import pandas as pd
import numpy as np
from doubleml import DoubleMLData
from sklearn.base import clone
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LassoCV
from doubleml import DoubleMLPLIV
import sys

np.random.seed(12345)

# Load in data, set date format, and sort panel
df = pd.read_csv('sipp_clean.csv', header=0)
df_keep_ue = pd.read_csv('sipp_clean_keep_ue.csv', header=0)

df['date'] = pd.to_datetime(df['date'], format='%Ym%m')
df = df.sort_values(by=['person_id','date'])
df_keep_ue['date'] = pd.to_datetime(df_keep_ue['date'], format='%Ym%m')
df_keep_ue = df_keep_ue.sort_values(by=['person_id','date'])

# Setup OxCGRT variables for merge
components = pd.read_csv('components_monthly.csv', header=0)
components['date'] = pd.to_datetime(components['date'], format='%Ym%m')
oxcgrt_indeces = pd.read_csv('oxcgrt_indeces_monthly.csv', header=0)
oxcgrt_indeces['date'] = pd.to_datetime(oxcgrt_indeces['date'], format='%Ym%m')

# Uncomment below if you want to lag oxcgrt vars
components.sort_values('date', inplace=True)
oxcgrt_indeces.sort_values('date', inplace=True)
components = components.shift(12)
oxcgrt_indeces = oxcgrt_indeces.shift(12)

# Grab columns to drop from covariate list
component_cols = components.drop(['date', 'state_code'], axis=1).columns.values
oxcgrt_cols = oxcgrt_indeces.drop(['date', 'state_code'], axis=1).columns.values

# Merge in OxCGRT vars
df = df.merge(components, 'left', ['date', 'state_code'])
df = df.merge(oxcgrt_indeces, 'left', ['date', 'state_code'])
df_keep_ue = df_keep_ue.merge(components, 'left', ['date', 'state_code'])
df_keep_ue = df_keep_ue.merge(oxcgrt_indeces, 'left', ['date', 'state_code'])

# Fill in 2018-2019 dates with 0
for column in components:
    df[column] = df[column].fillna(0)
    df_keep_ue[column] = df_keep_ue[column].fillna(0)

for column in oxcgrt_indeces:
    df[column] = df[column].fillna(0)
    df_keep_ue[column] = df_keep_ue[column].fillna(0)

# Flag entire panel if ever remote to drop for proper comparison
df['remote_any_flag'] = df.groupby('person_id')['remote_any'].transform('max')
df['remote_some_flag'] = df.groupby('person_id')['remote_some'].transform('max')
df['remote_primary_flag'] = df.groupby('person_id')['remote_primary'].transform('max')
df_keep_ue['remote_any_flag'] = df_keep_ue.groupby('person_id')['remote_any'].transform('max')
df_keep_ue['remote_some_flag'] = df_keep_ue.groupby('person_id')['remote_some'].transform('max')
df_keep_ue['remote_primary_flag'] = df_keep_ue.groupby('person_id')['remote_primary'].transform('max')

# Create instruments
df['iv_stringency_agg'] = df['stringency_index'] * df['DN_class_agg']
df['iv_stringency'] = df['stringency_index'] * df['DN_class']
df_keep_ue['iv_stringency_agg'] = df_keep_ue['stringency_index'] * df_keep_ue['DN_class_agg']
df_keep_ue['iv_stringency'] = df_keep_ue['stringency_index'] * df_keep_ue['DN_class']

# Create indicators
indicator_columns = ['household_relationship', 'worker_class', 'employer_size', 'occupation_code_agg', 'industry_code_agg', 'state_code', 'date']
#indicator_columns = ['household_relationship', 'worker_class', 'employer_size', 'occupation_code', 'industry_code', 'state_code', 'date']
for column in indicator_columns:
    temp = pd.get_dummies(df[column]).rename(columns=lambda x: f'{column}_' + str(x))
    df = pd.concat([df, temp], axis=1)
    temp2 = pd.get_dummies(df_keep_ue[column]).rename(columns=lambda x: f'{column}_' + str(x))
    df_keep_ue = pd.concat([df_keep_ue, temp], axis=1)

# Drop unused vars from dataset
df = df.drop(['jobid_1', 'rtanf_mnyn', 'tjb2_jobhrs1', 'monthly_earnings_total', 'monthly_hours', 'max_state',
              'miss1', 'missing_tjb2_jobhrs1', 'avg_earnings', 'ln_monthly_earnings_yoy_forward', 'ln_wage_yoy_forward',
              'remote_fraction', 'remote_fraction_0', 'remote_fraction_lt_50', 'remote_fraction_gt_50', 'remote_fraction_1',
              'exp_hsgraduate', 'exp_somecollege', 'exp_associates', 'exp_bachelors', 'exp_highered', 'remote_any_later',
              'remote_any_plus_later', 'remote_some_later', 'remote_some_plus_later', 'remote_primary_later',
              'remote_primary_plus_later',], axis=1)
df_keep_ue = df_keep_ue.drop(['jobid_1', 'rtanf_mnyn', 'tjb2_jobhrs1', 'monthly_earnings_total', 'monthly_hours', 'max_state',
              'miss1', 'missing_tjb2_jobhrs1', 'avg_earnings', 'ln_monthly_earnings_yoy_forward', 'ln_wage_yoy_forward',
              'remote_fraction', 'remote_fraction_0', 'remote_fraction_lt_50', 'remote_fraction_gt_50', 'remote_fraction_1',
              'exp_hsgraduate', 'exp_somecollege', 'exp_associates', 'exp_bachelors', 'exp_highered', 'remote_any_later',
              'remote_any_plus_later', 'remote_some_later', 'remote_some_plus_later', 'remote_primary_later',
              'remote_primary_plus_later',], axis=1)

# With all indicators, easier to drop non-covariates
covariates = df.drop(['person_id', 'date', 'state_code', 'cal_year', 'person_weight', 'monthly_earnings', 'wage',
                      'remote_any', 'remote_some', 'remote_primary', 'days_remote', 'days_worked', 'panel_year',
                      'household_ID', 'person_number', 'survey_year', 'monthcode', 'household_relationship', 'eeduc',
                      'worker_class', 'employer_size', 'emp_status', 'occupation_code', 'industry_code', 'ln_monthly_earnings',
                      'ln_wage', 'ln_weekly_hours', 'industry', 'industry_code_agg', 'occupation', 'occupation_code_agg',
                      'iv_stringency', 'iv_stringency_agg', 'remote_any_flag', 'remote_some_flag', 'remote_primary_flag'], axis=1)
covariates = covariates.drop(component_cols, axis=1)
covariates = covariates.drop(oxcgrt_cols, axis=1).columns.values.tolist()

# Set ML techniques
learner = RandomForestRegressor(n_estimators = 500, max_features = 'sqrt', max_depth = 5)
rf = clone(learner)
learner = LassoCV()
lasso = clone(learner)

# Drop obs with NaN
df = df.dropna()
df_keep_ue = df_keep_ue.dropna()

# DML Estimation:
with open("DML.out", 'w') as f:
    sys.stdout = f

    # # 2018-2021
    # # Stringency
    # # 2-digit
    # # Remote Any
    # # Earnings
    # data_earnings_any_stringency_2dig = DoubleMLData(df, 'ln_monthly_earnings', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Any, Stringency Index, 2-digit, 2018-2021:")
    # print(data_earnings_any_stringency_2dig)

    # # LASSO
    # obj_earnings_any_stringency_2dig_lasso = DoubleMLPLIV(data_earnings_any_stringency_2dig, lasso, lasso, lasso)
    # obj_earnings_any_stringency_2dig_lasso.fit()
    # print(obj_earnings_any_stringency_2dig_lasso)

    # # Random Forest
    # obj_earnings_any_stringency_2dig_rf = DoubleMLPLIV(data_earnings_any_stringency_2dig, rf, rf, rf)
    # obj_earnings_any_stringency_2dig_rf.fit()

    # print(obj_earnings_any_stringency_2dig_rf)

    # # Wage
    # data_wage_any_stringency_2dig = DoubleMLData(df, 'ln_wage', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Any, Stringency Index, 2-digit, 2018-2021:")
    # print(data_wage_any_stringency_2dig)

    # # LASSO
    # obj_wage_any_stringency_2dig_lasso = DoubleMLPLIV(data_wage_any_stringency_2dig, lasso, lasso, lasso)
    # obj_wage_any_stringency_2dig_lasso.fit()
    # print(obj_wage_any_stringency_2dig_lasso)

    # # Random Forest
    # obj_wage_any_stringency_2dig_rf = DoubleMLPLIV(data_wage_any_stringency_2dig, rf, rf, rf)
    # obj_wage_any_stringency_2dig_rf.fit()

    # print(obj_wage_any_stringency_2dig_rf)

    # # Hours
    # data_hours_any_stringency_2dig = DoubleMLData(df, 'ln_weekly_hours', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Any, Stringency Index, 2-digit, 2018-2021:")
    # print(data_hours_any_stringency_2dig)

    # # LASSO
    # obj_hours_any_stringency_2dig_lasso = DoubleMLPLIV(data_hours_any_stringency_2dig, lasso, lasso, lasso)
    # obj_hours_any_stringency_2dig_lasso.fit()
    # print(obj_hours_any_stringency_2dig_lasso)

    # # Random Forest
    # obj_hours_any_stringency_2dig_rf = DoubleMLPLIV(data_hours_any_stringency_2dig, rf, rf, rf)
    # obj_hours_any_stringency_2dig_rf.fit()

    # print(obj_hours_any_stringency_2dig_rf)

    # # Remote Some
    # df_some = df[df.remote_primary_flag != 1]
    # # Earnings
    # data_earnings_some_stringency_2dig = DoubleMLData(df_some, 'ln_monthly_earnings', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Some, Stringency Index, 2-digit, 2018-2021:")
    # print(data_earnings_some_stringency_2dig)

    # # LASSO
    # obj_earnings_some_stringency_2dig_lasso = DoubleMLPLIV(data_earnings_some_stringency_2dig, lasso, lasso, lasso)
    # obj_earnings_some_stringency_2dig_lasso.fit()
    # print(obj_earnings_some_stringency_2dig_lasso)

    # # Random Forest
    # obj_earnings_some_stringency_2dig_rf = DoubleMLPLIV(data_earnings_some_stringency_2dig, rf, rf, rf)
    # obj_earnings_some_stringency_2dig_rf.fit()

    # print(obj_earnings_some_stringency_2dig_rf)

    # # Wage
    # data_wage_some_stringency_2dig = DoubleMLData(df_some, 'ln_wage', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Some, Stringency Index, 2-digit, 2018-2021:")
    # print(data_wage_some_stringency_2dig)

    # # LASSO
    # obj_wage_some_stringency_2dig_lasso = DoubleMLPLIV(data_wage_some_stringency_2dig, lasso, lasso, lasso)
    # obj_wage_some_stringency_2dig_lasso.fit()
    # print(obj_wage_some_stringency_2dig_lasso)

    # # Random Forest
    # obj_wage_some_stringency_2dig_rf = DoubleMLPLIV(data_wage_some_stringency_2dig, rf, rf, rf)
    # obj_wage_some_stringency_2dig_rf.fit()

    # print(obj_wage_some_stringency_2dig_rf)

    # # Hours
    # data_hours_some_stringency_2dig = DoubleMLData(df_some, 'ln_weekly_hours', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Some, Stringency Index, 2-digit, 2018-2021:")
    # print(data_hours_some_stringency_2dig)

    # # LASSO
    # obj_hours_some_stringency_2dig_lasso = DoubleMLPLIV(data_hours_some_stringency_2dig, lasso, lasso, lasso)
    # obj_hours_some_stringency_2dig_lasso.fit()
    # print(obj_hours_some_stringency_2dig_lasso)

    # # Random Forest
    # obj_hours_some_stringency_2dig_rf = DoubleMLPLIV(data_hours_some_stringency_2dig, rf, rf, rf)
    # obj_hours_some_stringency_2dig_rf.fit()

    # print(obj_hours_some_stringency_2dig_rf)

    # # Remote Primary
    # df_primary = df[df.remote_some_flag != 1]
    # # Earnings
    # data_earnings_primary_stringency_2dig = DoubleMLData(df_primary, 'ln_monthly_earnings', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Primary, Stringency Index, 2-digit, 2018-2021:")
    # print(data_earnings_primary_stringency_2dig)

    # # LASSO
    # obj_earnings_primary_stringency_2dig_lasso = DoubleMLPLIV(data_earnings_primary_stringency_2dig, lasso, lasso, lasso)
    # obj_earnings_primary_stringency_2dig_lasso.fit()
    # print(obj_earnings_primary_stringency_2dig_lasso)

    # # Random Forest
    # obj_earnings_primary_stringency_2dig_rf = DoubleMLPLIV(data_earnings_primary_stringency_2dig, rf, rf, rf)
    # obj_earnings_primary_stringency_2dig_rf.fit()

    # print(obj_earnings_primary_stringency_2dig_rf)

    # # Wage
    # data_wage_primary_stringency_2dig = DoubleMLData(df_primary, 'ln_wage', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote primary, Stringency Index, 2-digit, 2018-2021:")
    # print(data_wage_primary_stringency_2dig)

    # # LASSO
    # obj_wage_primary_stringency_2dig_lasso = DoubleMLPLIV(data_wage_primary_stringency_2dig, lasso, lasso, lasso)
    # obj_wage_primary_stringency_2dig_lasso.fit()
    # print(obj_wage_primary_stringency_2dig_lasso)

    # # Random Forest
    # obj_wage_primary_stringency_2dig_rf = DoubleMLPLIV(data_wage_primary_stringency_2dig, rf, rf, rf)
    # obj_wage_primary_stringency_2dig_rf.fit()

    # print(obj_wage_primary_stringency_2dig_rf)

    # # Hours
    # data_hours_primary_stringency_2dig = DoubleMLData(df_primary, 'ln_weekly_hours', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote primary, Stringency Index, 2-digit, 2018-2021:")
    # print(data_hours_primary_stringency_2dig)

    # # LASSO
    # obj_hours_primary_stringency_2dig_lasso = DoubleMLPLIV(data_hours_primary_stringency_2dig, lasso, lasso, lasso)
    # obj_hours_primary_stringency_2dig_lasso.fit()
    # print(obj_hours_primary_stringency_2dig_lasso)

    # # Random Forest
    # obj_hours_primary_stringency_2dig_rf = DoubleMLPLIV(data_hours_primary_stringency_2dig, rf, rf, rf)
    # obj_hours_primary_stringency_2dig_rf.fit()

    # print(obj_hours_primary_stringency_2dig_rf)

    # # 4-digit
    # # Remote Any
    # # Earnings
    # data_earnings_any_stringency_4dig = DoubleMLData(df, 'ln_monthly_earnings', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Any, Stringency Index, 4-digit, 2018-2021:")
    # print(data_earnings_any_stringency_4dig)

    # # LASSO
    # obj_earnings_any_stringency_4dig_lasso = DoubleMLPLIV(data_earnings_any_stringency_4dig, lasso, lasso, lasso)
    # obj_earnings_any_stringency_4dig_lasso.fit()
    # print(obj_earnings_any_stringency_4dig_lasso)

    # # Random Forest
    # obj_earnings_any_stringency_4dig_rf = DoubleMLPLIV(data_earnings_any_stringency_4dig, rf, rf, rf)
    # obj_earnings_any_stringency_4dig_rf.fit()

    # print(obj_earnings_any_stringency_4dig_rf)

    # # Wage
    # data_wage_any_stringency_4dig = DoubleMLData(df, 'ln_wage', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Any, Stringency Index, 4-digit, 2018-2021:")
    # print(data_wage_any_stringency_4dig)

    # # LASSO
    # obj_wage_any_stringency_4dig_lasso = DoubleMLPLIV(data_wage_any_stringency_4dig, lasso, lasso, lasso)
    # obj_wage_any_stringency_4dig_lasso.fit()
    # print(obj_wage_any_stringency_4dig_lasso)

    # # Random Forest
    # obj_wage_any_stringency_4dig_rf = DoubleMLPLIV(data_wage_any_stringency_4dig, rf, rf, rf)
    # obj_wage_any_stringency_4dig_rf.fit()

    # print(obj_wage_any_stringency_4dig_rf)

    # # Hours
    # data_hours_any_stringency_4dig = DoubleMLData(df, 'ln_weekly_hours', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Any, Stringency Index, 4-digit, 2018-2021:")
    # print(data_hours_any_stringency_4dig)

    # # LASSO
    # obj_hours_any_stringency_4dig_lasso = DoubleMLPLIV(data_hours_any_stringency_4dig, lasso, lasso, lasso)
    # obj_hours_any_stringency_4dig_lasso.fit()
    # print(obj_hours_any_stringency_4dig_lasso)

    # # Random Forest
    # obj_hours_any_stringency_4dig_rf = DoubleMLPLIV(data_hours_any_stringency_4dig, rf, rf, rf)
    # obj_hours_any_stringency_4dig_rf.fit()

    # print(obj_hours_any_stringency_4dig_rf)

    # # Remote Some
    # df_some = df[df.remote_primary_flag != 1]
    # # Earnings
    # data_earnings_some_stringency_4dig = DoubleMLData(df_some, 'ln_monthly_earnings', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Some, Stringency Index, 4-digit, 2018-2021:")
    # print(data_earnings_some_stringency_4dig)

    # # LASSO
    # obj_earnings_some_stringency_4dig_lasso = DoubleMLPLIV(data_earnings_some_stringency_4dig, lasso, lasso, lasso)
    # obj_earnings_some_stringency_4dig_lasso.fit()
    # print(obj_earnings_some_stringency_4dig_lasso)

    # # Random Forest
    # obj_earnings_some_stringency_4dig_rf = DoubleMLPLIV(data_earnings_some_stringency_4dig, rf, rf, rf)
    # obj_earnings_some_stringency_4dig_rf.fit()

    # print(obj_earnings_some_stringency_4dig_rf)

    # # Wage
    # data_wage_some_stringency_4dig = DoubleMLData(df_some, 'ln_wage', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Some, Stringency Index, 4-digit, 2018-2021:")
    # print(data_wage_some_stringency_4dig)

    # # LASSO
    # obj_wage_some_stringency_4dig_lasso = DoubleMLPLIV(data_wage_some_stringency_4dig, lasso, lasso, lasso)
    # obj_wage_some_stringency_4dig_lasso.fit()
    # print(obj_wage_some_stringency_4dig_lasso)

    # # Random Forest
    # obj_wage_some_stringency_4dig_rf = DoubleMLPLIV(data_wage_some_stringency_4dig, rf, rf, rf)
    # obj_wage_some_stringency_4dig_rf.fit()

    # print(obj_wage_some_stringency_4dig_rf)

    # # Hours
    # data_hours_some_stringency_4dig = DoubleMLData(df_some, 'ln_weekly_hours', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Some, Stringency Index, 4-digit, 2018-2021:")
    # print(data_hours_some_stringency_4dig)

    # # LASSO
    # obj_hours_some_stringency_4dig_lasso = DoubleMLPLIV(data_hours_some_stringency_4dig, lasso, lasso, lasso)
    # obj_hours_some_stringency_4dig_lasso.fit()
    # print(obj_hours_some_stringency_4dig_lasso)

    # # Random Forest
    # obj_hours_some_stringency_4dig_rf = DoubleMLPLIV(data_hours_some_stringency_4dig, rf, rf, rf)
    # obj_hours_some_stringency_4dig_rf.fit()

    # print(obj_hours_some_stringency_4dig_rf)

    # # Remote Primary
    # df_primary = df[df.remote_some_flag != 1]
    # # Earnings
    # data_earnings_primary_stringency_4dig = DoubleMLData(df_primary, 'ln_monthly_earnings', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Primary, Stringency Index, 4-digit, 2018-2021:")
    # print(data_earnings_primary_stringency_4dig)

    # # LASSO
    # obj_earnings_primary_stringency_4dig_lasso = DoubleMLPLIV(data_earnings_primary_stringency_4dig, lasso, lasso, lasso)
    # obj_earnings_primary_stringency_4dig_lasso.fit()
    # print(obj_earnings_primary_stringency_4dig_lasso)

    # # Random Forest
    # obj_earnings_primary_stringency_4dig_rf = DoubleMLPLIV(data_earnings_primary_stringency_4dig, rf, rf, rf)
    # obj_earnings_primary_stringency_4dig_rf.fit()

    # print(obj_earnings_primary_stringency_4dig_rf)

    # # Wage
    # data_wage_primary_stringency_4dig = DoubleMLData(df_primary, 'ln_wage', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote primary, Stringency Index, 4-digit, 2018-2021:")
    # print(data_wage_primary_stringency_4dig)

    # # LASSO
    # obj_wage_primary_stringency_4dig_lasso = DoubleMLPLIV(data_wage_primary_stringency_4dig, lasso, lasso, lasso)
    # obj_wage_primary_stringency_4dig_lasso.fit()
    # print(obj_wage_primary_stringency_4dig_lasso)

    # # Random Forest
    # obj_wage_primary_stringency_4dig_rf = DoubleMLPLIV(data_wage_primary_stringency_4dig, rf, rf, rf)
    # obj_wage_primary_stringency_4dig_rf.fit()

    # print(obj_wage_primary_stringency_4dig_rf)

    # # Hours
    # data_hours_primary_stringency_4dig = DoubleMLData(df_primary, 'ln_weekly_hours', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote primary, Stringency Index, 4-digit, 2018-2021:")
    # print(data_hours_primary_stringency_4dig)

    # # LASSO
    # obj_hours_primary_stringency_4dig_lasso = DoubleMLPLIV(data_hours_primary_stringency_4dig, lasso, lasso, lasso)
    # obj_hours_primary_stringency_4dig_lasso.fit()
    # print(obj_hours_primary_stringency_4dig_lasso)

    # # Random Forest
    # obj_hours_primary_stringency_4dig_rf = DoubleMLPLIV(data_hours_primary_stringency_4dig, rf, rf, rf)
    # obj_hours_primary_stringency_4dig_rf.fit()

    # print(obj_hours_primary_stringency_4dig_rf)

    # # 2020-2021
    # df = df[df.cal_year != 2018]
    # df = df[df.cal_year != 2019]
    # # Stringency
    # # 2-digit
    # # Remote Any
    # # Earnings
    # data_earnings_any_stringency_2dig = DoubleMLData(df, 'ln_monthly_earnings', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Any, Stringency Index, 2-digit, 2020-2021:")
    # print(data_earnings_any_stringency_2dig)

    # # LASSO
    # obj_earnings_any_stringency_2dig_lasso = DoubleMLPLIV(data_earnings_any_stringency_2dig, lasso, lasso, lasso)
    # obj_earnings_any_stringency_2dig_lasso.fit()
    # print(obj_earnings_any_stringency_2dig_lasso)

    # # Random Forest
    # obj_earnings_any_stringency_2dig_rf = DoubleMLPLIV(data_earnings_any_stringency_2dig, rf, rf, rf)
    # obj_earnings_any_stringency_2dig_rf.fit()

    # print(obj_earnings_any_stringency_2dig_rf)

    # # Wage
    # data_wage_any_stringency_2dig = DoubleMLData(df, 'ln_wage', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Any, Stringency Index, 2-digit, 2020-2021:")
    # print(data_wage_any_stringency_2dig)

    # # LASSO
    # obj_wage_any_stringency_2dig_lasso = DoubleMLPLIV(data_wage_any_stringency_2dig, lasso, lasso, lasso)
    # obj_wage_any_stringency_2dig_lasso.fit()
    # print(obj_wage_any_stringency_2dig_lasso)

    # # Random Forest
    # obj_wage_any_stringency_2dig_rf = DoubleMLPLIV(data_wage_any_stringency_2dig, rf, rf, rf)
    # obj_wage_any_stringency_2dig_rf.fit()

    # print(obj_wage_any_stringency_2dig_rf)

    # # Hours
    # data_hours_any_stringency_2dig = DoubleMLData(df, 'ln_weekly_hours', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Any, Stringency Index, 2-digit, 2020-2021:")
    # print(data_hours_any_stringency_2dig)

    # # LASSO
    # obj_hours_any_stringency_2dig_lasso = DoubleMLPLIV(data_hours_any_stringency_2dig, lasso, lasso, lasso)
    # obj_hours_any_stringency_2dig_lasso.fit()
    # print(obj_hours_any_stringency_2dig_lasso)

    # # Random Forest
    # obj_hours_any_stringency_2dig_rf = DoubleMLPLIV(data_hours_any_stringency_2dig, rf, rf, rf)
    # obj_hours_any_stringency_2dig_rf.fit()

    # print(obj_hours_any_stringency_2dig_rf)

    # # Remote Some
    # df_some = df[df.remote_primary_flag != 1]
    # # Earnings
    # data_earnings_some_stringency_2dig = DoubleMLData(df_some, 'ln_monthly_earnings', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Some, Stringency Index, 2-digit, 2020-2021:")
    # print(data_earnings_some_stringency_2dig)

    # # LASSO
    # obj_earnings_some_stringency_2dig_lasso = DoubleMLPLIV(data_earnings_some_stringency_2dig, lasso, lasso, lasso)
    # obj_earnings_some_stringency_2dig_lasso.fit()
    # print(obj_earnings_some_stringency_2dig_lasso)

    # # Random Forest
    # obj_earnings_some_stringency_2dig_rf = DoubleMLPLIV(data_earnings_some_stringency_2dig, rf, rf, rf)
    # obj_earnings_some_stringency_2dig_rf.fit()

    # print(obj_earnings_some_stringency_2dig_rf)

    # # Wage
    # data_wage_some_stringency_2dig = DoubleMLData(df_some, 'ln_wage', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Some, Stringency Index, 2-digit, 2020-2021:")
    # print(data_wage_some_stringency_2dig)

    # # LASSO
    # obj_wage_some_stringency_2dig_lasso = DoubleMLPLIV(data_wage_some_stringency_2dig, lasso, lasso, lasso)
    # obj_wage_some_stringency_2dig_lasso.fit()
    # print(obj_wage_some_stringency_2dig_lasso)

    # # Random Forest
    # obj_wage_some_stringency_2dig_rf = DoubleMLPLIV(data_wage_some_stringency_2dig, rf, rf, rf)
    # obj_wage_some_stringency_2dig_rf.fit()

    # print(obj_wage_some_stringency_2dig_rf)

    # # Hours
    # data_hours_some_stringency_2dig = DoubleMLData(df_some, 'ln_weekly_hours', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Some, Stringency Index, 2-digit, 2020-2021:")
    # print(data_hours_some_stringency_2dig)

    # # LASSO
    # obj_hours_some_stringency_2dig_lasso = DoubleMLPLIV(data_hours_some_stringency_2dig, lasso, lasso, lasso)
    # obj_hours_some_stringency_2dig_lasso.fit()
    # print(obj_hours_some_stringency_2dig_lasso)

    # # Random Forest
    # obj_hours_some_stringency_2dig_rf = DoubleMLPLIV(data_hours_some_stringency_2dig, rf, rf, rf)
    # obj_hours_some_stringency_2dig_rf.fit()

    # print(obj_hours_some_stringency_2dig_rf)

    # # Remote Primary
    # df_primary = df[df.remote_some_flag != 1]
    # # Earnings
    # data_earnings_primary_stringency_2dig = DoubleMLData(df_primary, 'ln_monthly_earnings', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Primary, Stringency Index, 2-digit, 2020-2021:")
    # print(data_earnings_primary_stringency_2dig)

    # # LASSO
    # obj_earnings_primary_stringency_2dig_lasso = DoubleMLPLIV(data_earnings_primary_stringency_2dig, lasso, lasso, lasso)
    # obj_earnings_primary_stringency_2dig_lasso.fit()
    # print(obj_earnings_primary_stringency_2dig_lasso)

    # # Random Forest
    # obj_earnings_primary_stringency_2dig_rf = DoubleMLPLIV(data_earnings_primary_stringency_2dig, rf, rf, rf)
    # obj_earnings_primary_stringency_2dig_rf.fit()

    # print(obj_earnings_primary_stringency_2dig_rf)

    # # Wage
    # data_wage_primary_stringency_2dig = DoubleMLData(df_primary, 'ln_wage', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote primary, Stringency Index, 2-digit, 2020-2021:")
    # print(data_wage_primary_stringency_2dig)

    # # LASSO
    # obj_wage_primary_stringency_2dig_lasso = DoubleMLPLIV(data_wage_primary_stringency_2dig, lasso, lasso, lasso)
    # obj_wage_primary_stringency_2dig_lasso.fit()
    # print(obj_wage_primary_stringency_2dig_lasso)

    # # Random Forest
    # obj_wage_primary_stringency_2dig_rf = DoubleMLPLIV(data_wage_primary_stringency_2dig, rf, rf, rf)
    # obj_wage_primary_stringency_2dig_rf.fit()

    # print(obj_wage_primary_stringency_2dig_rf)

    # # Hours
    # data_hours_primary_stringency_2dig = DoubleMLData(df_primary, 'ln_weekly_hours', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote primary, Stringency Index, 2-digit, 2020-2021:")
    # print(data_hours_primary_stringency_2dig)

    # # LASSO
    # obj_hours_primary_stringency_2dig_lasso = DoubleMLPLIV(data_hours_primary_stringency_2dig, lasso, lasso, lasso)
    # obj_hours_primary_stringency_2dig_lasso.fit()
    # print(obj_hours_primary_stringency_2dig_lasso)

    # # Random Forest
    # obj_hours_primary_stringency_2dig_rf = DoubleMLPLIV(data_hours_primary_stringency_2dig, rf, rf, rf)
    # obj_hours_primary_stringency_2dig_rf.fit()

    # print(obj_hours_primary_stringency_2dig_rf)

    # # 4-digit
    # # Remote Any
    # # Earnings
    # data_earnings_any_stringency_4dig = DoubleMLData(df, 'ln_monthly_earnings', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Any, Stringency Index, 4-digit, 2020-2021:")
    # print(data_earnings_any_stringency_4dig)

    # # LASSO
    # obj_earnings_any_stringency_4dig_lasso = DoubleMLPLIV(data_earnings_any_stringency_4dig, lasso, lasso, lasso)
    # obj_earnings_any_stringency_4dig_lasso.fit()
    # print(obj_earnings_any_stringency_4dig_lasso)

    # # Random Forest
    # obj_earnings_any_stringency_4dig_rf = DoubleMLPLIV(data_earnings_any_stringency_4dig, rf, rf, rf)
    # obj_earnings_any_stringency_4dig_rf.fit()

    # print(obj_earnings_any_stringency_4dig_rf)

    # # Wage
    # data_wage_any_stringency_4dig = DoubleMLData(df, 'ln_wage', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Any, Stringency Index, 4-digit, 2020-2021:")
    # print(data_wage_any_stringency_4dig)

    # # LASSO
    # obj_wage_any_stringency_4dig_lasso = DoubleMLPLIV(data_wage_any_stringency_4dig, lasso, lasso, lasso)
    # obj_wage_any_stringency_4dig_lasso.fit()
    # print(obj_wage_any_stringency_4dig_lasso)

    # # Random Forest
    # obj_wage_any_stringency_4dig_rf = DoubleMLPLIV(data_wage_any_stringency_4dig, rf, rf, rf)
    # obj_wage_any_stringency_4dig_rf.fit()

    # print(obj_wage_any_stringency_4dig_rf)

    # # Hours
    # data_hours_any_stringency_4dig = DoubleMLData(df, 'ln_weekly_hours', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Any, Stringency Index, 4-digit, 2020-2021:")
    # print(data_hours_any_stringency_4dig)

    # # LASSO
    # obj_hours_any_stringency_4dig_lasso = DoubleMLPLIV(data_hours_any_stringency_4dig, lasso, lasso, lasso)
    # obj_hours_any_stringency_4dig_lasso.fit()
    # print(obj_hours_any_stringency_4dig_lasso)

    # # Random Forest
    # obj_hours_any_stringency_4dig_rf = DoubleMLPLIV(data_hours_any_stringency_4dig, rf, rf, rf)
    # obj_hours_any_stringency_4dig_rf.fit()

    # print(obj_hours_any_stringency_4dig_rf)

    # # Remote Some
    # df_some = df[df.remote_primary_flag != 1]
    # # Earnings
    # data_earnings_some_stringency_4dig = DoubleMLData(df_some, 'ln_monthly_earnings', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Some, Stringency Index, 4-digit, 2020-2021:")
    # print(data_earnings_some_stringency_4dig)

    # # LASSO
    # obj_earnings_some_stringency_4dig_lasso = DoubleMLPLIV(data_earnings_some_stringency_4dig, lasso, lasso, lasso)
    # obj_earnings_some_stringency_4dig_lasso.fit()
    # print(obj_earnings_some_stringency_4dig_lasso)

    # # Random Forest
    # obj_earnings_some_stringency_4dig_rf = DoubleMLPLIV(data_earnings_some_stringency_4dig, rf, rf, rf)
    # obj_earnings_some_stringency_4dig_rf.fit()

    # print(obj_earnings_some_stringency_4dig_rf)

    # # Wage
    # data_wage_some_stringency_4dig = DoubleMLData(df_some, 'ln_wage', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote Some, Stringency Index, 4-digit, 2020-2021:")
    # print(data_wage_some_stringency_4dig)

    # # LASSO
    # obj_wage_some_stringency_4dig_lasso = DoubleMLPLIV(data_wage_some_stringency_4dig, lasso, lasso, lasso)
    # obj_wage_some_stringency_4dig_lasso.fit()
    # print(obj_wage_some_stringency_4dig_lasso)

    # # Random Forest
    # obj_wage_some_stringency_4dig_rf = DoubleMLPLIV(data_wage_some_stringency_4dig, rf, rf, rf)
    # obj_wage_some_stringency_4dig_rf.fit()

    # print(obj_wage_some_stringency_4dig_rf)

    # # Hours
    # data_hours_some_stringency_4dig = DoubleMLData(df_some, 'ln_weekly_hours', 'remote_some', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote Some, Stringency Index, 4-digit, 2020-2021:")
    # print(data_hours_some_stringency_4dig)

    # # LASSO
    # obj_hours_some_stringency_4dig_lasso = DoubleMLPLIV(data_hours_some_stringency_4dig, lasso, lasso, lasso)
    # obj_hours_some_stringency_4dig_lasso.fit()
    # print(obj_hours_some_stringency_4dig_lasso)

    # # Random Forest
    # obj_hours_some_stringency_4dig_rf = DoubleMLPLIV(data_hours_some_stringency_4dig, rf, rf, rf)
    # obj_hours_some_stringency_4dig_rf.fit()

    # print(obj_hours_some_stringency_4dig_rf)

    # # Remote Primary
    # df_primary = df[df.remote_some_flag != 1]
    # # Earnings
    # data_earnings_primary_stringency_4dig = DoubleMLData(df_primary, 'ln_monthly_earnings', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Earnings, Remote Primary, Stringency Index, 4-digit, 2020-2021:")
    # print(data_earnings_primary_stringency_4dig)

    # # LASSO
    # obj_earnings_primary_stringency_4dig_lasso = DoubleMLPLIV(data_earnings_primary_stringency_4dig, lasso, lasso, lasso)
    # obj_earnings_primary_stringency_4dig_lasso.fit()
    # print(obj_earnings_primary_stringency_4dig_lasso)

    # # Random Forest
    # obj_earnings_primary_stringency_4dig_rf = DoubleMLPLIV(data_earnings_primary_stringency_4dig, rf, rf, rf)
    # obj_earnings_primary_stringency_4dig_rf.fit()

    # print(obj_earnings_primary_stringency_4dig_rf)

    # # Wage
    # data_wage_primary_stringency_4dig = DoubleMLData(df_primary, 'ln_wage', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Wage, Remote primary, Stringency Index, 4-digit, 2020-2021:")
    # print(data_wage_primary_stringency_4dig)

    # # LASSO
    # obj_wage_primary_stringency_4dig_lasso = DoubleMLPLIV(data_wage_primary_stringency_4dig, lasso, lasso, lasso)
    # obj_wage_primary_stringency_4dig_lasso.fit()
    # print(obj_wage_primary_stringency_4dig_lasso)

    # # Random Forest
    # obj_wage_primary_stringency_4dig_rf = DoubleMLPLIV(data_wage_primary_stringency_4dig, rf, rf, rf)
    # obj_wage_primary_stringency_4dig_rf.fit()

    # print(obj_wage_primary_stringency_4dig_rf)

    # # Hours
    # data_hours_primary_stringency_4dig = DoubleMLData(df_primary, 'ln_weekly_hours', 'remote_primary', covariates, 'iv_stringency_agg', 'date')
    # print("Hours, Remote primary, Stringency Index, 4-digit, 2020-2021:")
    # print(data_hours_primary_stringency_4dig)

    # # LASSO
    # obj_hours_primary_stringency_4dig_lasso = DoubleMLPLIV(data_hours_primary_stringency_4dig, lasso, lasso, lasso)
    # obj_hours_primary_stringency_4dig_lasso.fit()
    # print(obj_hours_primary_stringency_4dig_lasso)

    # # Random Forest
    # obj_hours_primary_stringency_4dig_rf = DoubleMLPLIV(data_hours_primary_stringency_4dig, rf, rf, rf)
    # obj_hours_primary_stringency_4dig_rf.fit()

    # print(obj_hours_primary_stringency_4dig_rf)

    # Test
    df_test = df
    # 2018-2021
    data_test = DoubleMLData(df_test, 'ln_monthly_earnings', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2018-2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)

    data_test = DoubleMLData(df_test, 'ln_wage', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2018-2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)

    data_test = DoubleMLData(df_test, 'ln_weekly_hours', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2018-2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)

    data_test = DoubleMLData(df_test, 'emp_status', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2018-2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)

    # 2020-2021
    df_test = df_test[df_test.cal_year != 2018]
    df_test = df_test[df_test.cal_year != 2019]
    df_test = df_test[df_test.cal_year != 2020]
    data_test = DoubleMLData(df_test, 'ln_monthly_earnings', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)

    data_test = DoubleMLData(df_test, 'ln_wage', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)

    data_test = DoubleMLData(df_test, 'ln_weekly_hours', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)

    data_test = DoubleMLData(df_test, 'emp_status', 'remote_any', covariates, 'iv_stringency_agg', 'date')
    print("Test (2021):")
    print(data_test)

    # LASSO
    obj_test_lasso = DoubleMLPLIV(data_test, lasso, lasso, lasso)
    obj_test_lasso.fit()
    print(obj_test_lasso)

    # Random Forest
    obj_test_rf = DoubleMLPLIV(data_test, rf, rf, rf)
    obj_test_rf.fit()
    print(obj_test_rf)
