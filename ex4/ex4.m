x=load('ex4x.dat');
y=load('ex4y.dat');


[m, n] = size(x);
x = [ones(m, 1), x];%增加一列

pos = find(y == 1); 
neg = find(y == 0);

plot(x(pos, 2), x(pos,3), '+'); hold on
plot(x(neg, 2), x(neg, 3), 'o')

xlabel('exam1 value');
ylabel('exam2 value');
legend('Admitted','Not admitted');

% Initialize fitting parameters
theta = zeros(n+1, 1);

% Define the sigmoid function 匿名函数
g = inline('1.0 ./ (1.0 + exp(-z))'); 

% Newton's method
MAX_ITR = 7;
J = zeros(MAX_ITR, 1);

for i = 1:MAX_ITR
    % 计算假设函数
    z = x * theta;
    h = g(z);%转换成logistic函数
    
    % 计算梯度和hession矩阵
    % 下面的公式等同于求和公式
    grad = (1/m).*x' * (h-y);%梯度的矢量表示法
    H = (1/m).*x' * diag(h) * diag(1-h) * x;%hessian矩阵的矢量表示法
    
    % 计算损失函数
    J(i) =(1/m)*sum(-y.*log(h) - (1-y).*log(1-h));%损失函数的矢量表示法
    
    %计算θ
    theta = theta - H\grad;
end

display(theta);

% 计算第一次考试20分，第二次考试80分
prob = 1 - g([1, 20, 80]*theta);

%画出分界面
% Plot Newton's method result
% Only need 2 points to define a line, so choose two endpoints
plot_x = [min(x(:,2))-2,  max(x(:,2))+2];
% 
plot_y = (-1./theta(3)).*(theta(2).*plot_x +theta(1));
plot(plot_x, plot_y)
legend('Admitted', 'Not admitted', 'Decision Boundary')
hold off

% Plot J
figure
plot(0:MAX_ITR-1, J, 'o--', 'MarkerFaceColor', 'r', 'MarkerSize', 8)
xlabel('Iteration'); ylabel('J')
% Display J



