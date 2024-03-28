x=load('ex2x.dat');
y=load('ex2y.dat');
m=length(x);
x=[ones(m,1),x];
sigma=std(x);%标准差
mu=mean(x);%均值
%按标准差进行缩放
x(:,2)=(x(:,2)-mu(2))./sigma(2);
x(:,3)=(x(:,3)-mu(3))./sigma(3);

theta=zeros(size(x(1,:)))';%1*n
alpha=0.1;
J=zeros(50,1);

for num_iterations = 1:50
    J(num_iterations) = 0.5*m*(x*theta-y)'*(x*theta-y);

    theta = theta-alpha/m*x'*(x*theta-y);
end

figure;
plot(0:49,J(1:50),'g-');
xlabel('iterations');
ylabel('J Cost');

theta = zeros(size(x(1,:)))'; % initialize fitting parameters
alpha = 0.01;%% Your initial learning rate %%
J1 = zeros(50, 1); 
%迭代50次
for num_iterations = 1:50
    J1(num_iterations) = 0.5*m*(x*theta-y)'*(x*theta-y);

    theta = theta-alpha/m*x'*(x*theta-y);
end

theta = zeros(size(x(1,:)))'; % initialize fitting parameters
alpha = 0.03;%% Your initial learning rate %%
J2= zeros(50, 1); 
%迭代50次
for num_iterations = 1:50
    J2(num_iterations) = 0.5*m*(x*theta-y)'*(x*theta-y);

    theta = theta-alpha/m*x'*(x*theta-y);
end

theta = zeros(size(x(1,:)))'; % initialize fitting parameters
alpha = 0.1;%% Your initial learning rate %%
J3= zeros(50, 1); 
%迭代50次
for num_iterations = 1:50
    J3(num_iterations) = 0.5*m*(x*theta-y)'*(x*theta-y);

    theta = theta-alpha/m*x'*(x*theta-y);
end
plot(0:49, J1(1:50), 'b-');
hold on;
plot(0:49, J2(1:50), 'r-');
plot(0:49, J3(1:50), 'k-');
plot(0:49,J(1:50),'g-');

theta = zeros(size(x(1,:)))'; % initialize fitting parameters
alpha = 0.1;%% Your initial learning rate %%

%迭代50
for num_iterations = 1:50

    theta = theta-alpha/m*x'*(x*theta-y);
end
format long
disp(theta);

predic_X = [1,(1650- mu(2))/ sigma(2),(3 - mu(3))/ sigma(3)];
predic_Y = predic_X*theta;
disp(predic_Y);

h=@(x,theta) x*theta;
u=(x'*x)\x'*y;
disp(u);
t1=(1650-mu(2))./sigma(2);
t2=(3-mu(3))./sigma(3);
disp(h([1,t1,t2],u));


