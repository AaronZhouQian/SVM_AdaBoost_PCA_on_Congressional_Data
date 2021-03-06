%Adaboost

training_data=csvread('training_data.csv');
testing_data=csvread('testing_data.csv');

democrat_indices=find(training_data(:,1)==1);
republican_indices=find(training_data(:,1)==-1);
X0=training_data(democrat_indices,:);
X1=training_data(republican_indices,:);
%removing the labels
X0=X0(:,2:end);
X1=X1(:,2:end);

M=10
[params, weights] = boostlearn(X0.', X1.', M);

X=[X0.',X1.'];
C=boosteval(X,params,weights);

predicted_democrat_indices=find(C==1);
predicted_republican_indices=find(C==-1);

num_errors_training=sum(predicted_democrat_indices>216);

num_errors_training=num_errors_training+sum(predicted_republican_indices<217)
%num_errors=17
%training_accuracy=331/348=95.1%


%Observation: when we increase M, num_errors is always 17, i.e. the training
%accuracy doesn't increase with M.

%now we test our model

democrat_testing_indices=find(testing_data(:,1)==1);
republican_testing_indices=find(testing_data(:,1)==-1);
X0_testing=testing_data(democrat_testing_indices,:);
X1_testing=testing_data(republican_testing_indices,:);
%removing the labels
X0_testing=X0_testing(:,2:end);
X1_testing=X1_testing(:,2:end);

X_testing=[X0_testing.',X1_testing.'];
C_testing_labels=boosteval(X_testing,params,weights);

testing_predicted_democrat_indices=find(C_testing_labels==1);
testing_predicted_republican_indices=find(C_testing_labels==-1);

testing_num_errors=sum(testing_predicted_democrat_indices>51);
testing_num_errors=testing_num_errors+sum(testing_predicted_republican_indices<52)

%accuracy=85/87=97.7%




