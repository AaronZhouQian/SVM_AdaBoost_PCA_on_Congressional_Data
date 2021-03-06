source boosteval.m;
source boostlearn.m;
source weaklearn.m;
source weakeval.m;

The above four files are from the lab so we omit them here.

We downloaded the datafile house-votes-84.data.txt from the webpage
https://archive.ics.uci.edu/ml/machine-learning-databases/voting-records/

Using bash shell scripting, we changed democrat to 1, republican to -1,
y to 1, n to -1, ? to 0 and saved the resulting datafile as votes.csv

sed 's/democrat/1/;s/republican/-1/;s/y/1/g;s/n/-1/g;s/?/0/g' <house-votes-84.data.txt >votes.csv

Using a python script we generated a training dataset consisting of 80% of the original data,
i.e. 348 out of 435 voting patterns of the members of congress, and used the remaining 20% of the
data as the testing dataset.

The python script is as follows:
#-----------------------#
#!/usr/local/bin/python
import numpy as np
import random

filename="156Project/votes.csv"
array=np.genfromtxt(filename,dtype="int",delimiter=",")

population_size=array.shape[0]
population_indices=np.arange(population_size)
training_indices=random.sample(population_indices,int(population_size*0.8))
testing_indices=list(set(population_indices)-set(training_indices))

training_data=array[training_indices,:]
testing_data=array[testing_indices,:]
np.savetxt("testing_data.csv",testing_data,delimiter=",",fmt="%d")
np.savetxt("training_data.csv",training_data,delimiter=",",fmt="%d")


% -1 = Republican
%  1 = Democrat
%  1 = Yes
% -1 = No
%  0 = ?
votes = csvread('votes.csv'); %Creates 435 by 17 array 


t = votes(:,1); % True labels of D or R

X = votes(:, 2:end); % Data : Voting record
N = size(X,1); %435
D = size(X,2); %16
gamma = 0.005;
[w,b] = softsvm_proj(X, t, gamma);
%w = [0.0762;
%    0.0118;
%    0.1909;
%   -0.4809;
%   -0.1359;
%    0.0151;
%   -0.0353;
%    0.0447;
%    0.1054;
%   -0.0326;
%    0.1320;
%   -0.1404;
%   -0.0518;
%   -0.0623;
%    0.0557;
%   -0.0269 ];
%b = 0.2675;


x_axis = X * w + b;
figure

plot(t, x_axis, 'b')
title('Classification')
xlabel('t, the correct labels')
ylabel('X*w +b')


% Most and least distinguishable vote for classification
w_square = w.^2;
[max_val_vote max_ind_vote] = max(w_square); %4=physician_fee_freeze
[min_val_vote min_ind_vote] = min(w_square); %2=water-project-cost-sharing
% These results make snse if you look at the probabilities for them from 
% data description online.

[min_val_person, min_index_person] = min(x_axis); %303 --> Most Republican
[max_val_person, max_index_person] = max(x_axis); %106 --> Most Democratic


R_indices = find(t==-1);
D_indices = find(t== 1);

incorrectNumR = size(find(x_axis(R_indices) > 0)); %Number of incorrectly classified R = 8
incorrectNumD = size(find(x_axis(D_indices) < 0)); %Number of incorrectly classified D = 16


%% Do soft SVM on 80% and test on 20%
trainingX = csvread('training_data.csv');
testingX = csvread('testing_data.csv');

t_training = trainingX(:,1); % True labels of D or R

trainingX = trainingX(:, 2:end); % Data : Voting record
N_training = size(trainingX,1); 
D_training = size(trainingX,2); %16

[w_training,b_training] = softsvm_proj(trainingX, t_training, gamma);
%b_training = 0.2648;
%w_training = [
%    0.0643;
%    0.0258;
%    0.2078;
%   -0.4054;
%   -0.1456;
%    0.0166;
%   -0.0133;
%    0.0687;
%    0.1113;
%   -0.0379;
%    0.1344;
%   -0.1264;
%   -0.0504;
%   -0.0570;
%    0.0613;
%   -0.0032];

t_testing = testingX(:,1);
testingX = testingX(:, 2:end);
N_testing = size(testingX,1);
D_testing = size(testingX, 2);
testing_predictions = zeros(N_testing, 1);
num_correct = 0; %4  (4.6% incorrect)
num_incorrect = 0; %83 (95.4% correct)
for i = 1:N_testing
    data_point = testingX(i,:);
    temp = dot(w_training, data_point) + b_training;
    if (temp > 0)
        testing_predictions(i) = 1;
    else
        testing_predictions(i) = -1;
    end %if
    
    if(testing_predictions(i) == t_testing(i))
        num_correct = num_correct + 1;
    else
        num_incorrect = num_incorrect + 1;
    end %if
end %for_loop
 
 %% ================================================================%%
 %%PCA on data
 cov_mat = cov(X);
 [U S V] = svd(cov_mat);
 PCs = U;
 PC1 = PCs(:,1);
 PC2 = PCs(:,2);
 
 % Project data onto first two PCs
 x_axis = zeros(N,1);
 y_axis = zeros(N,1);
 for i = 1:N
     data_point = X(i, :);
     x_axis(i) = dot(data_point, PC1);
     y_axis(i) = dot(data_point, PC2);
     
 end %for_loop
 
 figure
 hold on

scatter(x_axis(R_indices), y_axis(R_indices), 'r')
 scatter(x_axis(D_indices), y_axis(D_indices), 'b')
 title('PCA')
 xlabel('PC1')
 ylabel('PC2')
 hold off


 %% ================== ADABoost Algorithm ================== %%

%Need to first make data two dimensional, so squishing it down onto 2 PCs
%scatter(x_axis(R_indices), y_axis(R_indices), 'r')
%scatter(x_axis(D_indices), y_axis(D_indices), 'b')

dems = zeros(2,size(D_indices, 1));
dems(1, :) = x_axis(D_indices)';
dems(2, :) = y_axis(D_indices)';

repubs = zeros(2,size(R_indices, 1));
repubs(1, :) = x_axis(R_indices)';
repubs(2, :) = y_axis(R_indices)';
%dems = X(D_indices, :);

%repubs = X(R_indices, :);

min_size = min(size(dems,2), size(repubs,2))
dems = dems(:, 1:min_size);
repubs = repubs(:, 1:min_size);

X0 = dems;
X1 = repubs;

[params, weights] = boostlearn(X0, X1, 2);

C5_0 = boosteval(X0, params, weights);
C5_1 = boosteval(X1, params, weights);


% iterate through c50, c51 and if its 1 plot it in one color, and it if 0 plot it in another color.
scatter1 = zeros((min_size *2), 2);
scatter2 = zeros((min_size *2), 2);
scatter1_size = 1;
scatter2_size = 1;
for i = 1:min_size

    if (C5_0(i) == 1)
        scatter1(scatter1_size, 1) = (X0(1, i));
        scatter1(scatter1_size, 2) = (X0(2, i));
        scatter1_size = scatter1_size + 1;
    else
        scatter2(scatter2_size,1) = (X0(1,i));
        scatter2(scatter2_size,2) = (X0(2,i));
        scatter2_size = scatter2_size + 1;
    endif
end

for i = 1:min_size

    if (C5_1(i) == 1)
        scatter1(scatter1_size, 1) = (X1(1, i));
        scatter1(scatter1_size, 2) = (X1(2, i));
        scatter1_size = scatter1_size + 1;
    else
        scatter2(scatter2_size,1) = (X1(1,i));
        scatter2(scatter2_size,2) = (X1(2,i));
        scatter2_size = scatter2_size + 1;
    endif
end

figure

hold on
scatter(scatter1(:,1), scatter1(:,2), 'b')
scatter(scatter2(:,1), scatter2(:,2), 'r')
title("AdaBoost classification with 2 classes")
hold off



#------------START-----------#
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

num_errors=sum(predicted_democrat_indices>216);
num_errors=num_errors+sum(predicted_republican_indices<217);
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
testing_num_errors=testing_num_errors+sum(testing_predicted_republican_indices<52);

%accuracy=85/87=97.7%

#------------ END -----------#



#------------------------------START-------------------------------------------#
%Adaboost on dimensionally reduced dataset

%first we get the principal components
votes = csvread('votes.csv'); %Creates 435 by 17 array
X = votes(:, 2:end); % Data : Voting record
N = size(X,1); %435
D = size(X,2); %16
cov_mat = cov(X);
[U S V] = svd(cov_mat);
PCs = U;
PC1 = PCs(:,1);
PC2 = PCs(:,2);
%------------%

training_data=csvread('training_data.csv');
testing_data=csvread('testing_data.csv');

democrat_indices=find(training_data(:,1)==1);
republican_indices=find(training_data(:,1)==-1);
X0_training=training_data(democrat_indices,:);
X1_training=training_data(republican_indices,:);
%removing the labels
X0_training=X0_training(:,2:end);
X1_training=X1_training(:,2:end);

%now we project the data to the 2 components

num_training_democrats=size(X0_training,1);
num_training_republicans=size(X1_training,1);
projected_X0_training=zeros(num_training_democrats,2);
projected_X1_training=zeros(num_training_republicans,2);
for i=1:num_training_democrats
projected_X0_training(i,1)=X0_training(i,:)*PC1;
projected_X0_training(i,2)=X0_training(i,:)*PC2;
end

for i=1:num_training_republicans
projected_X1_training(i,1)=X1_training(i,:)*PC1;
projected_X1_training(i,2)=X1_training(i,:)*PC2;
end


M=10
[params, weights] = boostlearn(projected_X0_training.', projected_X1_training.', M);

X=[projected_X0_training.',projected_X1_training.'];
C=boosteval(X,params,weights);

predicted_democrat_indices=find(C==1);
predicted_republican_indices=find(C==-1);

num_errors=sum(predicted_democrat_indices>216);
num_errors=num_errors+sum(predicted_republican_indices<217);
%num_errors=21
%training_accuracy=327/348=94.0%

%------------%
%now we test our model

democrat_testing_indices=find(testing_data(:,1)==1);
republican_testing_indices=find(testing_data(:,1)==-1);
X0_testing=testing_data(democrat_testing_indices,:);
X1_testing=testing_data(republican_testing_indices,:);
%removing the labels
X0_testing=X0_testing(:,2:end);
X1_testing=X1_testing(:,2:end);



%now we project the data to the 2 components

num_testing_democrats=size(X0_testing,1);
num_testing_republicans=size(X1_testing,1);
projected_X0_testing=zeros(num_testing_democrats,2);
projected_X1_testing=zeros(num_testing_republicans,2);
for i=1:num_testing_democrats
projected_X0_testing(i,1)=X0_testing(i,:)*PC1;
projected_X0_testing(i,2)=X0_testing(i,:)*PC2;
end

for i=1:num_testing_republicans
projected_X1_testing(i,1)=X1_testing(i,:)*PC1;
projected_X1_testing(i,2)=X1_testing(i,:)*PC2;
end

X_testing=[projected_X0_testing.',projected_X1_testing.'];
C_testing_labels=boosteval(X_testing,params,weights);

testing_predicted_democrat_indices=find(C_testing_labels==1);
testing_predicted_republican_indices=find(C_testing_labels==-1);

testing_num_errors=sum(testing_predicted_democrat_indices>51);
testing_num_errors=testing_num_errors+sum(testing_predicted_republican_indices<52);

%accuracy=78/87=89.7%

#--------------------------------END----------------------------------------#


#-------------------------------START---------------------------------------#
%AdaBoost on Dimensionally Reduced Data (entire dataset)
votes = csvread('votes.csv'); %Creates 435 by 17 array
t = votes(:,1); % True labels of D or R

X = votes(:, 2:end); % Data : Voting record
N = size(X,1); %435
D = size(X,2); %16

R_indices = find(t==-1);
D_indices = find(t== 1);
cov_mat = cov(X);
[U S V] = svd(cov_mat);
PCs = U;
PC1 = PCs(:,1);
PC2 = PCs(:,2);

X0=X(D_indices,:);
X1=X(R_indices,:);

num_democrats=size(X0,1);
num_republicans=size(X1,1);
projected_X0=zeros(num_democrats,2);
projected_X1=zeros(num_republicans,2);
for i=1:num_democrats
projected_X0(i,1)=X0(i,:)*PC1;
projected_X0(i,2)=X0(i,:)*PC2;
end

for i=1:num_republicans
projected_X1(i,1)=X1(i,:)*PC1;
projected_X1(i,2)=X1(i,:)*PC2;
end


M=10
[params, weights] = boostlearn(projected_X0.', projected_X1.', M);
X=[projected_X0.',projected_X1.'];
C=boosteval(X,params,weights);


figure
hold on
for i=1:num_democrats
if C(i)==1
scatter(projected_X0(i,1),projected_X0(i,2),'b')
else
scatter(projected_X0(i,1),projected_X0(i,2),'b*')
end
end

for i=1:num_republicans
if C(num_democrats+i)==-1
scatter(projected_X1(i,1),projected_X1(i,2),'r')
else
scatter(projected_X1(i,1),projected_X1(i,2),'r*')
end
end
title('AdaBoost on Dimensionally Reduced Data')
xlabel('1st Principal Component')
ylabel('2nd Principal Component')
hold off


%plot adaboost decision boundaries
grid=zeros(10000,2);

for i=1:100
for j=1:100
grid((i-1)*100+j,1)=x(i);
grid((i-1)*100+j,2)=x(j);
end
end

C=boosteval(grid.',params,weights);
            
            figure
            hold on
            for i=1:10000
            if C(i)==1
            scatter(grid(i,1),grid(i,2),20,'b','o','filled')
            else
            scatter(grid(i,1),grid(i,2),20,'r','o','filled')
            end
            end
            
            
            title('AdaBoost Boundary by Grid Points')
            xlabel('1st Principal Component')
            ylabel('2nd Principal Component')
            hold off
            
#-------------------------------END------------------------------------------#
            
            
            
#------------------------------START-----------------------------------------#
            %plotting the decision boundary for SVM projected to the first two PCs.
            
            
            votes = csvread('votes.csv'); %Creates 435 by 17 array
            t = votes(:,1); % True labels of D or R
            
            X = votes(:, 2:end); % Data : Voting record
            N = size(X,1); %435
            D = size(X,2); %16
            
            R_indices = find(t==-1);
            D_indices = find(t== 1);
            
            cov_mat = cov(X);
            [U S V] = svd(cov_mat);
            PCs = U;
            PC1 = PCs(:,1);
            PC2 = PCs(:,2);
            
            w = [0.0762;
                 0.0118;
                 0.1909;
                 -0.4809;
                 -0.1359;
                 0.0151;
                 -0.0353;
                 0.0447;
                 0.1054;
                 -0.0326;
                 0.1320;
                 -0.1404;
                 -0.0518;
                 -0.0623;
                 0.0557;
                 -0.0269 ];
            b = 0.2675;
            
            alpha_1=w.'*PC1;
            alpha_2=w.'*PC2;
            
            x=linspace(-4,4);
            y=(-alpha_1/alpha_2)*x-b/alpha_2;
            
            x_axis = zeros(N,1);
            y_axis = zeros(N,1);
            for i = 1:N
            data_point = X(i, :);
            x_axis(i) = dot(data_point, PC1);
            y_axis(i) = dot(data_point, PC2);
            end %for_loop
            
            figure
            hold on
            scatter(x_axis(R_indices), y_axis(R_indices), 'r')
            scatter(x_axis(D_indices), y_axis(D_indices), 'b')
            title('SVM Decision Boundary Projection to the First Two Principal Components')
            xlabel('1st Principal Component')
            ylabel('2nd Principal Component')
            
            plot(x,y,'LineWidth',2);
            axis([-4 4 -4 4]);
            
            hold off
#--------------------------------- END ------------------------------------------#
            
            
            
#-------------------------------START-----------------------------------------#
            %SVM on reduced data
            
            votes = csvread('votes.csv'); %Creates 435 by 17 array
            X = votes(:, 2:end); % Data : Voting record
            N = size(X,1); %435
            D = size(X,2); %16
            cov_mat = cov(X);
            [U S V] = svd(cov_mat);
            PCs = U;
            PC1 = PCs(:,1);
            PC2 = PCs(:,2);
            %------------%
            
            training_data=csvread('training_data.csv');
            testing_data=csvread('testing_data.csv');
            
            N_training=size(training_data,1);
            N_testing=size(testing_data,1);
            
            democrat_indices=find(training_data(:,1)==1);
            republican_indices=find(training_data(:,1)==-1);
            X0_training=training_data(democrat_indices,:);
            X1_training=training_data(republican_indices,:);
            %removing the labels
            X0_training=X0_training(:,2:end);
            X1_training=X1_training(:,2:end);
            
            %now we project the data to the 2 components
            
            num_training_democrats=size(X0_training,1);
            num_training_republicans=size(X1_training,1);
            projected_X0_training=zeros(num_training_democrats,2);
            projected_X1_training=zeros(num_training_republicans,2);
            for i=1:num_training_democrats
            projected_X0_training(i,1)=X0_training(i,:)*PC1;
            projected_X0_training(i,2)=X0_training(i,:)*PC2;
            end
            
            for i=1:num_training_republicans
            projected_X1_training(i,1)=X1_training(i,:)*PC1;
            projected_X1_training(i,2)=X1_training(i,:)*PC2;
            end
            
            
            projected_X_training=[projected_X0_training;projected_X1_training];
            t1=ones(216,1);
            tminus1=-ones(132,1);
            t=[t1;tminus1];
            
            [w,b]=softsvm_proj(projected_X_training,t,0.05);
            
            %w=[-0.6777;-0.4998]
            %b=0.8745
            
            training_predictions=zeros(N_training,1);
            for i=1:N_training
            temp=dot(w,projected_X_training(i,:))+b;
            if(temp>0)
            training_predictions(i,1)=1;
            else
            training_predictions(i,1)=-1;
            end
            end
            
            
            training_errors=sum(training_predictions(1:216,1)==-1)+sum(training_predictions(217:348,1)==1);
            %training_errors=26;
            %accuracy=322/348=92.53%
            
            %now we test our model
            
            democrat_testing_indices=find(testing_data(:,1)==1);
            republican_testing_indices=find(testing_data(:,1)==-1);
            X0_testing=testing_data(democrat_testing_indices,:);
            X1_testing=testing_data(republican_testing_indices,:);
            %removing the labels
            X0_testing=X0_testing(:,2:end);
            X1_testing=X1_testing(:,2:end);
            
            %now we project the data to the 2 components
            
            num_testing_democrats=size(X0_testing,1);
            num_testing_republicans=size(X1_testing,1);
            projected_X0_testing=zeros(num_testing_democrats,2);
            projected_X1_testing=zeros(num_testing_republicans,2);
            for i=1:num_testing_democrats
            projected_X0_testing(i,1)=X0_testing(i,:)*PC1;
            projected_X0_testing(i,2)=X0_testing(i,:)*PC2;
            end
            
            for i=1:num_testing_republicans
            projected_X1_testing(i,1)=X1_testing(i,:)*PC1;
            projected_X1_testing(i,2)=X1_testing(i,:)*PC2;
            end
            
            projected_X_testing=[projected_X0_testing;projected_X1_testing];
            
            testing_predictions=zeros(N_testing,1);
            
            for i=1:N_testing
            temp=dot(w,projected_X_testing(i,:))+b;
            if(temp>0)
            testing_predictions(i,1)=1;
            else
            testing_predictions(i,1)=-1;
            end
            end
            
            testing_errors=sum(testing_predictions(1:51,1)==-1)+sum(testing_predictions(52:87,1)==1);
            %testing_errors=10;
            %accuracy=77/87=88.50%

#-------------------------------END-----------------------------------------#





 
