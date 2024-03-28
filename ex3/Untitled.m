%导入数据
x1=load('ex3red.dat');
x2=load('ex3blue.dat');
x3=load('ex3green.dat');

figure
hold on
%绘制散点图，用红色圆形画红点，设置为红色
%用蓝色星形画，设置为蓝色
plot(x1(:,1),x1(:,2),'ro','markerfacecolor','r');
plot(x2(:,1),x2(:,2),'b*','markerfacecolor','b');
xlabel('x');
ylabel('y');
%设置坐标轴范围
xlim([0.00 10.00])
ylim([0.00 10.00])
% m1,m2是均值
m1=mean(x1);
m2=mean(x2);
%计算类间散度
Sb=(m1-m2)'*(m1-m2);
%计算类内散度
Sw=(x1-m1)'*(x1-m1)+(x2-m2)'*(x2-m2);
%计算矩阵sb的逆矩阵你和矩阵sb的乘积特征值和特征向量
%inv（sw)是逆矩阵，*是矩阵乘法，eig()是求特征向量矩阵和特征值矩阵
[V,L]=eig(inv(Sw)*Sb);
%找出特征值矩阵种最大的特征值a和在矩阵种的位置b
[a,b]=max(max(L));
theta = Sw\(m1-m2)';
disp(theta);
figure
hold on
plot(x1(:,1),x1(:,2),'ro','markerfacecolor','r');
plot(x2(:,1),x2(:,2),'b*','markerfacecolor','b');
%画投影的直线
x=linspace(0,10,100);
y=(theta(2)/theta(1))*x;
plot(x,y,'black')
title('LDA for two-classes')
xlabel('x')
ylabel('y')
%计算投影点
%首先计算投影直线的斜率和截距
k=theta(2)/theta(1);
s1=size(x1,1);
s2=size(x2,1);
x1_tag=[];
x2_tag=[];
%对两组点进行投影
for i=1:s1
    y0=x1(i,2);
    x0=x1(i,1);
    xn=(k*(y0-b)+x0)/(k^2+1);%投影的横坐标
    x1_tag=[x1_tag;xn];%存入
end
y1_tag=k*x1_tag + b;%再通过横坐标和直线算出纵坐标
x1_final=[x1_tag y1_tag];%找到投影点
%对另一组投影
for i=1:s2
    y0=x2(i,2);
    x0=x2(i,1);
    xn=(k*(y0-b)+x0)/(k^2+1);
    x2_tag=[x2_tag;xn];
end
y2_tag=k*x2_tag + b;
x2_final=[x2_tag y2_tag];

figure
hold on
%画出点
plot(x1(:,1),x1(:,2),'ro','markerfacecolor','r');
plot(x2(:,1),x2(:,2),'b*','markerfacecolor','b');
%投影直线
x=linspace(0,10,100);
y=(theta(2)/theta(1))*x + b;
plot(x,y,'black')
title('LDA for two-classes')
xlabel('x')
ylabel('y')
%投影点
plot(x1_final(:,1),x1_final(:,2),'ro','markerfacecolor','r');
plot(x2_final(:,1),x2_final(:,2),'bo','markerfacecolor','b');