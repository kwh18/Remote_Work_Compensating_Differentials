#Import the pandas module. This code requires version 0.24 or higher
#	in order to use the Int64 and Float64 data types, which allow for
#	missing values
import pandas as pd

full_sample = pd.DataFrame()
for y in [2019,2020,2021,2022,2023]:
	#Read in the primary data file schema to get data-type information for
	#	each variable.
	rd_schema = pd.read_json('pu'+str(y)+'_schema.json')

	#Define Pandas data types based on the schema data-type information for both schema dataframes
	rd_schema['dtype'] = ['Int64' if x == 'integer' \
				else 'object' if x == 'string' \
				else 'Float64' if x == 'float' \
				else 'ERROR' \
				for x in rd_schema['dtype']]


	#Read in the primary data
	df_data = pd.read_csv('pu'+str(y)+'.csv',\
			names=rd_schema['name'],\
			#dtype expects a dictionary of key:values
			dtype = dict([(i,v) for i,v in zip(rd_schema['name'], rd_schema['dtype'])]),\
			#files are pipe-delimited
			sep='|',\
			header=0,\
			#Add variables for analysis here. If you receive an out-of-memory error,
			#	either select less columns, or consider using the Dask module
			usecols = [
			#Common case-identification variables
			'SSUID','PNUM','MONTHCODE','ERESIDENCEID','ERELRPE','SPANEL','SWAVE',\
			#The base weight and monthly in-survey-universe indicator
			'WPFINWGT','RIN_UNIV',\
			#Common demographics variables, including age at time of interview (TAGE)
			#	and monthly age during the reference period (TAGE_EHC)
			'ESEX','TAGE','TAGE_EHC','ERACE','EORIGIN','EEDUC',\
			#Income Variables
			'TPTOTINC','TPEARN_ALT','TJB1_ANNSAL1','TJB1_ANNSAL2','TJB1_ANNSAL3','TJB1_MTHLY1','TJB1_MTHLY2','TJB1_MTHLY3','TJB1_BWKLY1','TJB1_BWKLY2','TJB1_BWKLY3','TJB1_WKLY1','TJB1_WKLY2','TJB1_WKLY3',\
			'TJB1_HOURLY1','TJB1_HOURLY2','TJB1_HOURLY3','TJB1_OTHER1','TJB1_OTHER2','TJB1_OTHER3',\
			#Transfer Program variables
			'RTANF_MNYN',\
			#Standard Work Schedule variables
			'EJB1_DYSWKD','EJB1_PVTRPRM',\
			#WFH Schedule variables
			'EJB1_DYSWKDH','EJB1_PVWKTR9','EJB1_WSHMWRK',\
			#Employment variables
			'EJB1_BSLRYB','EJB1_CLWRK','EJB1_JBORSE','TJB1_IND','TJB1_OCC','EJB1_EMPSIZE','EJB1_JOBID','EJB2_JOBID', \
			#Hours Variables
			'EJB1_CHHOUR1','TJB1_JOBHRS1','TJB2_JOBHRS1','TJB1_WKHRS1','TJB1_WKHRS2','TJB1_WKHRS3','TJB1_WKHRS4','TJB1_WKHRS5',\
			#Unemployment variables
			'ENJ_BMONTH','ENJ_LKWRK','ENJFLAG',\
			#Marital History
			'EMS_EHC',\
			#Location Variables
			'TEHC_ST'\
				]
			)
	#Add in Survey Year Variable
	df_data['survey_year'] = y
	#preview the data		
	print(df_data.head())
	#Save data with limited variables
	df_data.to_csv('pu'+str(y)+'_limit.csv')

	full_sample = pd.concat([full_sample,df_data])
print(full_sample.head())
full_sample.to_csv('SIPP_full_sample.csv')

