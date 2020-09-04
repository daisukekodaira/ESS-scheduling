clear all;
clc;

%% kW

data2013_2014 = xlsread('data_total.xlsx',1); % ù��°��Ʈ : 2013�� 1�� ~ 2014�� 12�� ������

%% kmeans, 2013, train

X = data2013_2014(1:365,1:96); % �� : �ִ����(kW), 2013�� ������ ���

k = 4 % Ŭ������ ���� 4
[idx,c] = kmeans(X,k);

%% bayesian

meas = xlsread('newone_meas2.xlsx',1); % 2013�� 1�� ~ 2014�� 12�� (���ϸ����)
species = idx;

%# lets split into training/testing
training = meas(1:365,:); % 2013�� 1�� ~ 12�� (���ϸ����)
train_class = species(1:365,:); % 2013�� 1�� ~ 12�� (kmeans�з��Ѱ�)

confirm = meas(366:730,:); % 2014�� 1�� ~ Ȯ�� (���ϸ����)

%# train model
nb = NaiveBayes.fit(training, train_class);
%# prediction
y = nb.predict(confirm);

%% class data -> load data
for i = 1:1:365
for j = 1:1:4
    if y(i,1) == j
    result_C(i,:) = c(j,:); 
    end
end
end