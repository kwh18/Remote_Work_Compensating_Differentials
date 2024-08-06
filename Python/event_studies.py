import pandas as pd
import numpy as np
from datetime import datetime
import paneleventstudy
import matplotlib.pyplot as plt
import linearmodels as lm
import statsmodels.api as sm
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import LogisticRegression

df = pd.read_csv('sipp_clean_keep_ue.csv', header=0)

df['date'] = pd.to_datetime(df['date'], format='%Ym%m')
print(df)
df = df.sort_values(by=['person_id','date'])
df['emp_status_change'] = df.groupby('person_id')['emp_status'].diff()
df['ue_to_e'] = [1 if x == 1 else 0 for x in df['emp_status_change']]
df['e_to_ue'] = [1 if x == -1 else 0 for x in df['emp_status_change']]
df['ue_to_e_event'] = df.groupby('person_id')['ue_to_e'].cumsum()
df['e_to_ue_event'] = df.groupby('person_id')['e_to_ue'].cumsum()
df.loc[df['emp_status_change'].isnull(), 'ue_to_e'] = np.nan
df.loc[df['emp_status_change'].isnull(), 'e_to_ue'] = np.nan
df['ue_to_e_id'] = df.groupby('person_id')['ue_to_e'].max()
df['e_to_ue_id'] = df.groupby('person_id')['e_to_ue'].max()
df['control_ue_to_e'] = [1-x for x in df['ue_to_e_id']]
df['control_e_to_ue'] = [1-x for x in df['e_to_ue_id']]
df['person_id'] = df['person_id'].apply(str)
df.to_csv('df_test.csv')

df = paneleventstudy.gencohort(df, 'person_id', 'ue_to_e_event', 'date', cohort='cohort_ue_to_e', check_balance=False)
df = paneleventstudy.genreltime(df, 'person_id', 'ue_to_e_event', 'date', reltime='reltime_ue_to_e', check_balance=False)
event_study_ue_to_e_naive = paneleventstudy.naivetwfe_eventstudy(df, 'emp_status', 'ue_to_e_event', 'person_id', 'reltime_ue_to_e', 'date',
                                      ['age', 'age_sq', 'weekly_hours', 'female', 'hispanic', 'black', 'asian',
                                       'resid_race', 'hsgraduate', 'somecollege', 'associates', 'bachelors',
                                       'highered'],
                                      vcov_type='robust', check_balance=False)
event_study_ue_to_e_SA = paneleventstudy.interactionweighted_eventstudy(df, 'emp_status', 'ue_to_e_event', 'person_id', 'cohort_ue_to_e', 'reltime_ue_to_e', 'date',
                                      ['age', 'age_sq', 'weekly_hours', 'female', 'hispanic', 'black', 'asian',
                                       'resid_race', 'hsgraduate', 'somecollege', 'associates', 'bachelors',
                                       'highered'],
                                       vcov_type='robust', check_balance=False)
paneleventstudy.eventstudyplot(event_study_ue_to_e_naive, big_title='Employment Status around time of Employment', path_output='', name_output='event_study_ue_to_e_naive')
paneleventstudy.eventstudyplot(event_study_ue_to_e_SA, big_title='Employment Status around time of Employment', path_output='', name_output='event_study_ue_to_e_SA')

df = paneleventstudy.gencohort(df, 'person_id', 'e_to_ue_event', 'date', cohort='cohort_e_to_ue', check_balance=False)
df = paneleventstudy.genreltime(df, 'person_id', 'e_to_ue_event', 'date', reltime='reltime_e_to_ue', check_balance=False)
event_study_e_to_ue_naive = paneleventstudy.naivetwfe_eventstudy(df, 'emp_status', 'e_to_ue_event', 'person_id', 'reltime_e_to_ue', 'date',
                                      ['age', 'age_sq', 'weekly_hours', 'female', 'hispanic', 'black', 'asian',
                                       'resid_race', 'hsgraduate', 'somecollege', 'associates', 'bachelors',
                                       'highered'],
                                      vcov_type='robust', check_balance=False)
event_study_e_to_ue_SA = paneleventstudy.interactionweighted_eventstudy(df, 'emp_status', 'e_to_ue_event', 'person_id', 'cohort_e_to_ue', 'reltime_e_to_ue', 'date',
                                      ['age', 'age_sq', 'weekly_hours', 'female', 'hispanic', 'black', 'asian',
                                       'resid_race', 'hsgraduate', 'somecollege', 'associates', 'bachelors',
                                       'highered'],
                                       vcov_type='robust', check_balance=False)
paneleventstudy.eventstudyplot(event_study_e_to_ue_naive, big_title='Employment Status around time of Unemployment', path_output='', name_output='event_study_e_to_ue_naive')
paneleventstudy.eventstudyplot(event_study_e_to_ue_SA, big_title='Employment Status around time of Unemployment', path_output='', name_output='event_study_e_to_ue_SA')