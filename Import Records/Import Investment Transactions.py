import os       #used for setting the current working directory (if script is run from another location)
import pandas    #supports the use of dataframes (python by default only uses lists)
import sqlite3   #supports performing SQL transactions with sqlite




#######################  import csv files as dataframes  #######################

csvDf = pandas.read_csv("Investment Transactions/investment_transactions.csv",
    engine = 'python', skip_blank_lines = True, skipinitialspace = True, error_bad_lines = False, warn_bad_lines = False, skiprows = 5)




#######################  clean new records  #######################

#flip the order of the records so records are sorted old to new
csvDf = csvDf.sort_index(ascending=False, axis=0)
csvDf = csvDf.reset_index(drop=True)

#delete unneeded columns
##'axis = 1' says to drop the whole column
csvDf = csvDf.drop(['Security Type', 'Commission ($)', 'Fees ($)', 'Accrued Interest ($)', 'Settlement Date'], axis = 1)

#rename headers
csvDf.columns = ['transDate','transAccount','transDescription','securitySymbol', 'securityDescription',
         'transQuantity', 'securityPrice', 'transAmount']

#reformat transDate by converting from strings to datetimes
csvDf['transDate'] = pandas.to_datetime(csvDf['transDate'])

#convert transAmount from int to float
csvDf['transAmount'] = csvDf['transAmount'].astype(float)

#break csvDf into two dataframes based on transAccount
account_1CsvDf = csvDf.loc[csvDf['transAccount'] == 'ACCOUNT_1']
account_2CsvDf = csvDf.loc[csvDf['transAccount'] == 'ACCOUNT_2']

#delete transAccount columns
account_1CsvDf = account_1CsvDf.drop(['transAccount'], axis = 1)
account_2CsvDf = account_2CsvDf.drop(['transAccount'], axis = 1)

#throw an error if csvDf contains records that are not assigned to either account
unassignedRecords = csvDf[~csvDf['transAccount'].isin(['ACCOUNT_1', 'ACCOUNT_2']) ]
if not unassignedRecords.empty:
    print('\n', 'A RECORD EXISTS THAT IS NOT TIED TO EITHER INVESTMENT ACCOUNT:', '\n')
    print(unassignedRecords)
    input('\n' + 'Press enter to exit...')
    quit()




#######################  identify new records to import  #######################

#connect to the database and define the cursor
conn = sqlite3.connect("../SQLite Database/Sample Finance Records.db")
conn.execute("PRAGMA foreign_keys = 1") #enable the enforcement of foreign key constraints (for transCategory)
cursorObj = conn.cursor()


def create_sqlDf(sqlAccountName):
 
    #select records with the cursor then import the selection as a dataframe
    cursorObj.execute('SELECT transDate, transAmount FROM ' + sqlAccountName)
    sqlDf = pandas.DataFrame(cursorObj.fetchall(), columns = ['transDate', 'transAmount'])

    #convert transDate columns from strings to datetimes
    sqlDf['transDate'] = pandas.to_datetime(sqlDf['transDate'])

    return(sqlDf)

#create dataframes for database records
account_1SqlDf = create_sqlDf('Investment_1')
account_2SqlDf = create_sqlDf('Investment_2')


def identify_new_records(selectedCsvDf, selectedSqlDf):

    #compare csv records to existing records and save new ones to NewDf
    selectedNewDf = selectedCsvDf.merge(selectedSqlDf, how = 'outer' ,indicator=True).loc[lambda x : x['_merge']=='left_only']

    #delete _merge column from NewDf
    del selectedNewDf['_merge']

    return(selectedNewDf)

#create newDf for each account using the identify_new_records function
account_1NewDf = identify_new_records(account_1CsvDf, account_1SqlDf)
account_2NewDf = identify_new_records(account_2CsvDf, account_2SqlDf)




#######################  insert new records into database  #######################  

#if there are new records for an account, print the dataframe, prompt to import, and perform the import
def prompt_and_import(selectedNewDf, selectedCsvDf, selectedSqlDf, accountName, sqlAccountName):

    #check if there are new records to import
    if selectedNewDf.empty == False:
        
        #print records to import
        print('\n', 'New ', accountName, ' transactions:', '\n\n', selectedNewDf, '\n', sep='') #default separator is ' '
        
        #notify the user if there isn't overlap between old and new records
        if len(selectedNewDf.index) == len(selectedCsvDf.index):
            input('There is no overlap between old and new ' + accountName + ' transactions. ' +
            'Recommend downloading transactions with a larger date range.')


        #create a variable containing the date of the newest sql record
        newestSqlDate = selectedSqlDf['transDate'].max() 

        #check if there are records to import that are older than the most recent sql record. If so, ask if they should
        # be included in the import.
        if selectedNewDf['transDate'].min() < newestSqlDate:
            
            #print the old records in question
            print('\n', selectedNewDf.loc[selectedNewDf['transDate'] < newestSqlDate], sep='')

            #ask if the old records should be imported
            if (input('\n' + 'These new ' + accountName + ' transactions are older than those in the database.' +
            '\n' + 'Should they be included in the import? (y/n): ') != 'y'):
                
                #if not yes, only keep newer records
                selectedNewDf = selectedNewDf.loc[selectedNewDf['transDate'] >= newestSqlDate]

            #print records to import again
            print('\n', 'New ', accountName, ' transactions:', '\n\n', selectedNewDf, '\n', sep='')


        #prompt to import
        if input('Import new ' + accountName + ' transactions? (y/n): ') == 'y':
            print('Importing transactions...')
            
            #convert transDate columns from datetimes back to strings - otherwise a timestamp will be exported
            # along with the date
            selectedNewDf['transDate'] = selectedNewDf['transDate'].dt.strftime('%Y-%m-%d')

            #import
            selectedNewDf.to_sql(sqlAccountName, conn, if_exists = 'append', index = False)
        else:
            print(accountName, 'import aborted.')
    else:
        print('\n', 'No new ', accountName, ' transactions.', sep='')


#run the prompt_and_import function for each account
prompt_and_import(account_1NewDf, account_1CsvDf, account_1SqlDf, 'Account_1', 'Investment_1')
prompt_and_import(account_2NewDf, account_2CsvDf, account_2SqlDf, 'Account_2', 'Investment_2')

#close the sqlite3 cursor and database connection
cursorObj.close()
conn.close()

#prompt user to close command window
input('\n' + 'Press enter to exit...')