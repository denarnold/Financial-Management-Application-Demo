import pandas   #supports the use of dataframes (python by default only uses lists)
import sqlite3  #supports performing SQL transactions with sqlite
import os.path  #supports checking if a file exists
import csv      #used for importing csv files


#import renaming rules
with open('Description rules.csv') as csvfile:
    descriptionRules = [tuple(line) for line in csv.reader(csvfile)]

with open('Category rules.csv') as csvfile:
    categoryRules = [tuple(line) for line in csv.reader(csvfile)]




#######################  bank account class  #######################

class BankAccount:
    
    #specify the __init__ function
    def __init__(self, name, sqlTableName, csvAddress):
        self.name = name
        self.sqlTableName = sqlTableName
        self.csvAddress = csvAddress

    
    
    
    #######################  import csv files as dataframes  #######################

    #function to check if a csv file exists
    def check_for_csv(self):
        if os.path.exists(self.csvAddress):
            return True
        else:
            print('\n', 'No ', self.name, ' csv file found.', sep='')    
            return False
    

    #function to import a csv file as a dataframe
    def import_from_csv(self):
        self.csvRecords = pandas.read_csv(self.csvAddress)
        
        return self




    #######################  clean new records  #######################

    #function to clean a dataframe
    def clean_dataframes(self):
        #only keep relevant columns
        self.csvRecords = self.csvRecords.loc[:, ('Date', 'Description', 'Amount')]

        #rename dataframe headers
        self.csvRecords.columns = ['transDate','transOriginalDescription','transAmount']

        #reformat transDate by converting from strings to datetimes
        self.csvRecords['transDate'] = pandas.to_datetime(self.csvRecords['transDate'])

        #convert transAmount from string to float
        #  (remove dollar sign and properly format negative numbers from () to - in the process)
        #  (\ means the statement continues to the next line)
        self.csvRecords['transAmount'] = self.csvRecords['transAmount']\
            .replace('\$', '', regex=True)\
            .replace('\(', '-', regex=True)\
            .replace('\)', '', regex=True)\
            .astype(float)

        return self
    
    #function to flip the polarity of transactions so that expenses are negative
    #  (used for visa account)
    def invert_polarity(self):
        self.csvRecords['transAmount'] = self.csvRecords['transAmount'] * -1

        return self



    
    #######################  identify new records to import  #######################

    def identify_new_records(self):
    
        #select sql records with the cursor then import the selection as a dataframe
        cursorObj.execute('SELECT transDate, transAmount FROM ' + self.sqlTableName)
        self.sqlRecords = pandas.DataFrame(cursorObj.fetchall(), columns = ['transDate', 'transAmount'])

        #convert transDate columns from strings to datetimes
        self.sqlRecords['transDate'] = pandas.to_datetime(self.sqlRecords['transDate'])

        #compare csv records to existing sql records and only keep the new records
        self.newRecords = self.csvRecords.merge(self.sqlRecords, how = 'outer' ,indicator=True).loc[lambda x : x['_merge']=='left_only']

        #delete _merge column that resulted from the last step
        del self.newRecords['_merge']

        return self
    



    #######################  apply renaming rules to transDescription and transCategory columns  ######################   
    #  renaming lists are imported from renaming_rules.py

    #description rules function
    def description_rules(self):
        #add a transDescription column and populate with values from transOriginalDescription
        self.newRecords.insert(1, "transDescription", self.newRecords['transOriginalDescription'])

        #create an empty dictionary to store records to change
        changeDictionary = {}

        #loop through each row of the dataframe
        for x, row in self.newRecords.iterrows():
            #for the current row, assign the transOriginalDescription string to the variable xDescription
            xDescription = self.newRecords.loc[x, 'transOriginalDescription']

            #Loop through the descriptionRules list.
            #  Since each list item is a tuple containing two elements (the original description and the new description),
            #  the tuples can be unpacked by specifying multiple values in the 'for' statement, like 'val1, val2 in list'.
            #  Below, od represents the original description element and nd represents the new description element.
            for od, nd in descriptionRules:
                #check if the first string in the descriptionRules list (od) occurs anywhere in the xDescription string
                if od.lower() in xDescription.lower():  #.lower() makes the comparison case-insensitive
                    #If so, record the desired change to a dictionary.
                    #Set the dictionary key as the row number (x) and the value to the desired new description (nd)
                    #  It is not advised to edit the dataframe while looping through it, which is why changes are
                    #  being saved to a list)
                    changeDictionary[x] = nd

        #loop through the changeDictionary and apply changes to the dataframe
        for key in changeDictionary:
            self.newRecords.at[key, 'transDescription'] = changeDictionary[key]

        return self
        

    #category rules function
    def category_rules(self):

        #create an empty dictionary to store records to change
        changeDictionary = {}
        
        #loop through each row of the selected dataframe
        for x, row in self.newRecords.iterrows():
            #for the current row, assign the transOriginalDescription string to the variable xDescription
            xDescription = self.newRecords.loc[x, 'transOriginalDescription']

            #Loop through the categoriesRules list.
            #  Since each list item is a tuple containing two elements (the description and the category),
            #  the tuples can be unpacked by specifying multiple values in the 'for' statement, like 'val1, val2 in list'.
            #  Below, d represents the description tuple and c represents the category tuple.
            for d, c in categoryRules:
                #check if the first string in the categoryRules list (d) occurs anywhere in the xDescription string
                if d.lower() in xDescription.lower():  #.lower() makes the comparison case-insensitive
                    #if so, record the desired change to a dictionary.
                    #Set the dictionary key as the row number (x) and the value to the desired category (c)
                    ##It is not advised to edit the dataframe while looping through it, which is why changes are
                    ##being saved to a list)
                    changeDictionary[x] = c
                    
        #Loop through the changeDictionary and apply changes to the dataframe.
        #If the transCategory column does not yet exist, it will be created.
        for key in changeDictionary:
            self.newRecords.at[key, 'transCategory'] = changeDictionary[key]

        return self




    #######################  insert new records into database  #######################  

    #if there are new records for an account, print the dataframe, prompt to import, and perform the import
    def prompt_and_import(self):

        #check if there are new records to import
        if self.newRecords.empty == False:
            
            #print records to import
            print('\n', 'New ', self.name, ' transactions:', '\n\n', self.newRecords, '\n', sep='') #default separator is ' '
            
            #notify the user if there isn't overlap between old and new records
            if len(self.newRecords.index) == len(self.csvRecords.index):
                input('There is no overlap between old and new ' + self.name + ' transactions. ' +
                'Recommend downloading transactions with a larger date range.')


            #create a variable containing the date of the newest sql record
            newestSqlDate = self.sqlRecords['transDate'].max() 

            #check if there are records to import that are older than the most recent sql record. If so, ask if they should
            # be included in the import.
            if self.newRecords['transDate'].min() < newestSqlDate:
                
                #print the old records in question
                print('\n', self.newRecords.loc[self.newRecords['transDate'] < newestSqlDate], sep='')

                #ask if the old records should be imported
                if (input('\n' + 'These new ' + self.name + ' transactions are older than those in the database.' +
                '\n' + 'Should they be included in the import? (y/n): ') != 'y'):
                    
                    #if not yes, only keep newer records
                    self.newRecords = self.newRecords.loc[self.newRecords['transDate'] >= newestSqlDate]

                #print records to import again
                print('\n', 'New ', self.name, ' transactions:', '\n\n', self.newRecords, '\n', sep='')


            #prompt to import
            if input('Import new ' + self.name + ' transactions? (y/n): ') == 'y':
                print('Importing transactions...')
                
                #convert transDate columns from datetimes back to strings - otherwise a timestamp will be exported
                # along with the date
                self.newRecords['transDate'] = self.newRecords['transDate'].dt.strftime('%Y-%m-%d')

                #import
                self.newRecords.to_sql(self.sqlTableName, conn, if_exists = 'append', index = False)

            else:
                print(self.name, 'import aborted.')
        else:
            print('\n', 'No new ', self.name, ' transactions.', sep='')

        return self




#create objects from the BankAccount class
Visa = BankAccount('Visa', 'Visa_7651', 'Bank Transactions/visa.csv')
Checking = BankAccount('Checking', 'Checking_4883', 'Bank Transactions/checking.csv')
Savings = BankAccount('Savings', 'Savings_6893', 'Bank Transactions/savings.csv')

#connect to the database and define the cursor
conn = sqlite3.connect("../SQLite Database/Sample Finance Records.db")
conn.execute("PRAGMA foreign_keys = 1") #enable the enforcement of foreign key constraints (for transCategory)
cursorObj = conn.cursor()

#run objects through the methods if their csv files exist
if Visa.check_for_csv():
    Visa.import_from_csv()\
        .clean_dataframes()\
        .invert_polarity()\
        .identify_new_records()\
        .description_rules()\
        .category_rules()\
        .prompt_and_import()

if Checking.check_for_csv():
    Checking.import_from_csv()\
        .clean_dataframes()\
        .identify_new_records()\
        .description_rules()\
        .category_rules()\
        .prompt_and_import()

if Savings.check_for_csv():
    Savings.import_from_csv()\
        .clean_dataframes()\
        .identify_new_records()\
        .description_rules()\
        .category_rules()\
        .prompt_and_import()

#close the sqlite3 cursor and database connection
cursorObj.close()
conn.close()

#prompt user to close command window
input('\n' + 'Press enter to exit...')