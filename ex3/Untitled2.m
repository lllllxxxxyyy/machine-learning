%导入数据
x1=load('ex3red.dat');
x2=load('ex3blue.dat');
x3=load('ex3green.dat');
%画出点
hold on
plot(x1(:,1),x1(:,2),'ro','markerfacecolor','r');
plot(x2(:,1),x2(:,2),'b*','markerfacecolor','b');
plot(x3(:,1),x3(:,2),'gs','markerfacecolor','g');
xlabel('x');
ylabel('y');
title('scatter diagram of 3-classes');
xlim([0.00 10.00]);
ylim([0.00 10.00]);
%计算均值
m1=mean(x1);
m2=mean(x2);
m3=mean(x3);
m=mean([x1;x2;x3]);
%计算类间散度和类内散度
Sb=((m1-m)'*(m1-m)+(m2-m)'*(m2-m)+(m3-m)'*(m3-m))/3;
Sw=((x1-m1)'*(x1-m1)+(x2-m2)'*(x2-m2)+(x3-m3)'*(x3-m3))/3;
%inv（sw)是逆矩阵，*是矩阵乘法，eig()是求特征向量矩阵和特征值矩阵
[V,L]=eig(inv(Sw)*Sb);
[a,b]=max(max(L));
theta = V(:,b);
%计算斜率
k=theta(2)/theta(1);
%画图，画点和投影线
figure
hold on
plot(x1(:,1),x1(:,2),'ro','markerfacecolor','r');
plot(x2(:,1),x2(:,2),'b*','markerfacecolor','b');
plot(x3(:,1),x3(:,2),'gs','markerfacecolor','g');
xlim([0.00 10.00]);
ylim([0.00 10.00]);
xlabel('x');
ylabel('y');
x=linspace(0,10,100);
y=k*x+b;
plot(x,y,'black')
title('LDA for 3-classes')
xlabel('x')
ylabel('y')
hold off

%对三类点向直线投影，并画出投影的点
s1=size(x1,1);
s2=size(x2,1);
s3=size(x3,1);
x1_tag=[];
x2_tag=[];
x3_tag=[];
%对三组类分别进行for循环，算出投影的点
for i=1:s1
    y0=x1(i,2);
    x0=x1(i,1);
    xn=(k*(y0-b)+x0)/(k^2+1);
    x1_tag=[x1_tag;xn];
end
y1_tag=k*x1_tag + b;
x1_final=[x1_tag y1_tag];
for i=1:s2
    y0=x2(i,2);
    x0=x2(i,1);
    xn=(k*(y0-b)+x0)/(k^2+1);
    x2_tag=[x2_tag;xn];
end
y2_tag=k*x2_tag + b;
x2_final=[x2_tag y2_tag];
for i=1:s3
    y0=x3(i,2);
    x0=x3(i,1);
    xn=(k*(y0-b)+x0)/(k^2+1);
    x3_tag=[x3_tag;xn];
end
y3_tag=k*x3_tag+b;
x3_final=[x3_tag y3_tag];
%画出点，直线和投影点
figure
hold on
plot(x1(:,1),x1(:,2),'ro','markerfacecolor','r');
plot(x2(:,1),x2(:,2),'b*','markerfacecolor','b');
plot(x3(:,1),x3(:,2),'gs','markerfacecolor','g');
xlim([0.00 10.00]);
ylim([0.00 10.00]);
x=linspace(0,10,100);
y=k*x+b;
plot(x,y,'black')
title('LDA for 3-classes')
xlabel('x')
ylabel('y')
plot(x1_final(:,1),x1_final(:,2),'ro','markerfacecolor','r');
plot(x2_final(:,1),x2_final(:,2),'bo','markerfacecolor','b');
plot(x3_final(:,1),x3_final(:,2),'go','markerfacecolor','g');