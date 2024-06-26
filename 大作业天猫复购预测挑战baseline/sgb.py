import gc
import pandas as pd
import numpy as np

#导入分析库
from sklearn.model_selection import train_test_split
from sklearn.model_selection import StratifiedKFold
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LinearRegression
from sklearn.metrics import classification_report
#import lightgbm as lgb
import xgboost as xgb

import catboost as cat

from sklearn.metrics import roc_auc_score, roc_curve, auc
# LOCAL_QUICK = True
LOCAL_QUICK = False
sample_percent = 0.1

MORE_FE = False
# MORE_FE = True
FE_V1 = False if MORE_FE else True


# 加载数据
# 用户行为，使用format1进行加载
user_log = pd.read_csv('user_log_format1.csv', dtype={'time_stamp':'str'})

user_info = pd.read_csv('user_info_format1.csv')

train_data1 = pd.read_csv('train_format1.csv')

sub_data = pd.read_csv('test_format1.csv')
data_train = pd.read_csv('train_format2.csv')


# 采样测试
if LOCAL_QUICK:
    print('Local quick test: {}, rate is {}'.format(
        LOCAL_QUICK, sample_percent))
    data = user_log.sample(int(len(user_log) * sample_percent))
    data1 = user_info.sample(int(len(user_info) * sample_percent))
    data2 = train_data1.sample(int(len(train_data1) * sample_percent))
    # submission = sub_data.sample(int(len(sub_data) * sample_percent))
    submission = sub_data.copy()

else:
    print('All sample train')
    data = user_log.copy()
    data1 = user_info.copy()
    data2 = train_data1.copy()
    submission = sub_data.copy()
    del user_log, user_info, train_data1, sub_data
print('---data shape---')
#for df in [data, data1, data2, submission, data_train]:
#    print(df.shape)
data2['origin'] = 'train'
submission['origin'] = 'test'
matrix = pd.concat([data2, submission], ignore_index=True, sort=False)
matrix.drop(['prob'], axis=1, inplace=True)
# 连接user_info表，通过user_id关联
matrix = matrix.merge(data1, on='user_id', how='left')
# 使用merchant_id（原列名seller_id）
data.rename(columns={'seller_id':'merchant_id'}, inplace=True)
# 格式化
data['user_id'] = data['user_id'].astype('int32')
data['merchant_id'] = data['merchant_id'].astype('int32')
data['item_id'] = data['item_id'].astype('int32')
data['cat_id'] = data['cat_id'].astype('int32')
data['brand_id'].fillna(0, inplace=True)
data['brand_id'] = data['brand_id'].astype('int32')
data['time_stamp'] = pd.to_datetime(data['time_stamp'], format='%H%M')
# 缺失值填充
matrix['age_range'].fillna(0, inplace=True)
matrix['gender'].fillna(2, inplace=True)

# # gender用众数填充 表现更差
# matrix['gender'].fillna(matrix['gender'].mode()[0],inplace=True)
# # 年龄用中位数填充
# matrix['age_range'].fillna(matrix['age_range'].median(),inplace=True)

matrix['age_range'] = matrix['age_range'].astype('int8')
matrix['gender'] = matrix['gender'].astype('int8')
matrix['label'] = matrix['label'].astype('str')
matrix['user_id'] = matrix['user_id'].astype('int32')
matrix['merchant_id'] = matrix['merchant_id'].astype('int32')

del data1, data2
gc.collect()

##### 特征处理
##### User特征处理
groups = data.groupby(['user_id'])
# 用户交互行为数量 u1
temp = groups.size().reset_index().rename(columns={0:'u1'})
matrix = matrix.merge(temp, on='user_id', how='left')
# 使用agg 基于列的聚合操作，统计唯一值个数 item_id, cat_id, merchant_id, brand_id
temp = groups['item_id'].agg([('u2', 'nunique')]).reset_index()
matrix = matrix.merge(temp, on='user_id', how='left')
temp = groups['cat_id'].agg([('u3', 'nunique')]).reset_index()
matrix = matrix.merge(temp, on='user_id', how='left')
temp = groups['merchant_id'].agg([('u4', 'nunique')]).reset_index()
matrix = matrix.merge(temp, on='user_id', how='left')
temp = groups['brand_id'].agg([('u5', 'nunique')]).reset_index()
matrix = matrix.merge(temp, on='user_id', how='left')
# 时间间隔特征 u6 按照小时
temp = groups['time_stamp'].agg([('F_time', 'min'), ('L_time', 'max')]).reset_index()
temp['u6'] = (temp['L_time'] - temp['F_time']).dt.seconds/3600
matrix = matrix.merge(temp[['user_id', 'u6']], on='user_id', how='left')
# 统计操作类型为0，1，2，3的个数
temp = groups['action_type'].value_counts().unstack().reset_index().rename(
    columns={0:'u7', 1:'u8', 2:'u9', 3:'u10'})
matrix = matrix.merge(temp, on='user_id', how='left')

del temp
gc.collect()


##### 商家特征处理
groups = data.groupby(['merchant_id'])
# 商家被交互行为数量 m1
temp = groups.size().reset_index().rename(columns={0:'m1'})
matrix = matrix.merge(temp, on='merchant_id', how='left')
# 统计商家被交互的user_id, item_id, cat_id, brand_id 唯一值
temp = groups['user_id', 'item_id', 'cat_id', 'brand_id'].nunique().reset_index().rename(columns={
    'user_id':'m2',
    'item_id':'m3',
    'cat_id':'m4',
    'brand_id':'m5'})
matrix = matrix.merge(temp, on='merchant_id', how='left')
# 统计商家被交互的action_type 唯一值
temp = groups['action_type'].value_counts().unstack().reset_index().rename(
    columns={0:'m6', 1:'m7', 2:'m8', 3:'m9'})
matrix = matrix.merge(temp, on='merchant_id', how='left')

del temp
gc.collect()

# 按照merchant_id 统计随机负采样的个数
temp = data_train[data_train['label']==-1].groupby(['merchant_id']).size().reset_index().rename(columns={0:'m10'})
matrix = matrix.merge(temp, on='merchant_id', how='left')

##### 用户+商户特征
groups = data.groupby(['user_id', 'merchant_id'])
temp = groups.size().reset_index().rename(columns={0:'um1'})
matrix = matrix.merge(temp, on=['user_id', 'merchant_id'], how='left')
temp = groups['item_id', 'cat_id', 'brand_id'].nunique().reset_index().rename(columns={
    'item_id':'um2',
    'cat_id':'um3',
    'brand_id':'um4'
})
matrix = matrix.merge(temp, on=['user_id', 'merchant_id'], how='left')
temp = groups['action_type'].value_counts().unstack().reset_index().rename(columns={
    0:'um5',
    1:'um6',
    2:'um7',
    3:'um8'
})
matrix = matrix.merge(temp, on=['user_id', 'merchant_id'], how='left')
temp = groups['time_stamp'].agg([('frist', 'min'), ('last', 'max')]).reset_index()
temp['um9'] = (temp['last'] - temp['frist']).dt.seconds/3600
temp.drop(['frist', 'last'], axis=1, inplace=True)
matrix = matrix.merge(temp, on=['user_id', 'merchant_id'], how='left')

del temp
gc.collect()

matrix['r1'] = matrix['u9']/matrix['u7'] # 用户购买点击比
matrix['r2'] = matrix['m8']/matrix['m6'] # 商家购买点击比
matrix['r3'] = matrix['um7']/matrix['um5'] #不同用户不同商家购买点击比

matrix.fillna(0, inplace=True)

# # 修改age_range字段名称为 age_0, age_1, age_2... age_8
temp = pd.get_dummies(matrix['age_range'], prefix='age')
matrix = pd.concat([matrix, temp], axis=1)
temp = pd.get_dummies(matrix['gender'], prefix='g')
matrix = pd.concat([matrix, temp], axis=1)
matrix.drop(['age_range', 'gender'], axis=1, inplace=True)

del temp
gc.collect()

train_data = matrix[matrix['origin'] == 'train'].drop(['origin'], axis=1)
test_data = matrix[matrix['origin'] == 'test'].drop(['label', 'origin'], axis=1)

if not LOCAL_QUICK:
    if FE_V1:
        train_data.to_csv('train_data.csv')
        test_data.to_csv('test_data.csv')
    if MORE_FE:
        train_data.to_csv('train_data_moreFE.csv')
        test_data.to_csv('test_data_moreFE.csv')

del matrix
gc.collect()

# get data
if not LOCAL_QUICK:
    if FE_V1:
        train_data = pd.read_csv('train_data.csv')
        test_data = pd.read_csv('test_data.csv')
    if MORE_FE:
        train_data = pd.read_csv('train_data_moreFE.csv')
        test_data = pd.read_csv('test_data_moreFE.csv')

# FeatureSelect_QUICK = True # Feature Select
FeatureSelect_QUICK = False
if FeatureSelect_QUICK: # 使用部分样本进行快速特征选择
    train_data = train_data.sample(int(len(train_data) * sample_percent))

# train_data = train_data[train_col]
train_X, train_y = train_data.drop(['label'], axis=1), train_data['label']

del train_data

X_train, X_valid, y_train, y_valid = train_test_split(train_X, train_y, test_size=.2, random_state=42) # test_size=.3



def xgb_train(X_train, y_train, X_valid, y_valid, verbose=True):
    model_xgb = xgb.XGBClassifier(
        max_depth=10, # raw8
        n_estimators=1000,
        min_child_weight=300,
        colsample_bytree=0.8,
        subsample=0.8,
        eta=0.3,
        seed=42
    )

    model_xgb.fit(
        X_train,
        y_train,
        eval_metric='auc',
        eval_set=[(X_train, y_train), (X_valid, y_valid)],
        verbose=verbose,
        early_stopping_rounds=10 # 早停法，如果auc在10epoch没有进步就stop
    )
    print(model_xgb.best_score)
    return model_xgb

model_xgb = xgb_train(X_train, y_train, X_valid, y_valid, verbose=False)

prob = model_xgb.predict_proba(test_data)

submission['prob'] = pd.Series(prob[:,1])
# submission.drop(['origin'], axis=1, inplace=True)
submission.to_csv('submission_xgb.csv', index=False)