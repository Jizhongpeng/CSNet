function V = CS_FilterBank(InImg, PatchSize, NumFilters) 
% =======INPUT=============
% InImg            Input images (cell structure)  
% InImgIdx         Image index for InImg (column vector)
% PatchSize        the patch size, asumed to an odd number.
% NumFilters       the number of PCA filters in the bank.
% givenV           the PCA filters are given. 
% =======OUTPUT============
% V                PCA filter banks, arranged in column-by-column manner
% OutImg           filter output (cell structure)
% OutImgIdx        Image index for OutImg (column vector)
% ========= CITATION ============
% T.-H. Chan, K. Jia, S. Gao, J. Lu, Z. Zeng, and Y. Ma, 
% "PCANet: A simple deep learning baseline for image classification?" submitted to IEEE TPAMI. 
% ArXiv eprint: http://arxiv.org/abs/1404.3606 

% Tsung-Han Chan [thchan@ieee.org]
% Please email me if you find bugs, or have suggestions or questions!

addpath('./Utils')

% to efficiently cope with the large training samples, we randomly subsample 100000 training subset to learn PCA filter banks
ImgZ = length(InImg);
MaxSamples = 100000;
NumRSamples = min(ImgZ, MaxSamples); 
RandIdx = randperm(ImgZ);
RandIdx = RandIdx(1:NumRSamples);

%% Learning PCA filters (V)
NumChls = size(InImg{1},3);  % NumChlsΪͨ����Ŀ
Rx = zeros(NumChls*PatchSize^2,NumChls*PatchSize^2);
for i = RandIdx 
    % collect all the patches of the ith image in a matrix
    im = im2col_general(InImg{i},[PatchSize PatchSize]); 
    fprintf('size of InImg{i} is %dx%d\n',size(InImg{i},1),size(InImg{i},2))
    fprintf('size of im is %dx%d\n',size(im,1),size(im,2))
    im = bsxfun(@minus, im, mean(im)); % patch-mean removal 
    % sum of all the input images' covariance matrix
    Rx = Rx + im*im'; 
end
fprintf('size of Rx is %dx%d\n',size(Rx,1),size(Rx,2))
Rx = Rx/(NumRSamples*size(im,2));    % size of Rx is 49x49
% ������������
% [E D] = eig(Rx);
% [trash ind] = sort(diag(D),'descend');
% V = E(:,ind(1:NumFilters));  % principal eigenvectors  NumFilters=8
% size(ind);
V=[];
[img_cs_1d,Theta_1d]=getdata(Rx,3);
for s=1:NumFilters
    for i=1:width
            column_rec=cs_omp(img_cs_1d(:,i),Theta_1d,height,s);
            sparse_rec_1d(:,i)=column_rec';           % sparse representation
    end
    V=[V;reshape(column_rec,1,[])];
end

% ����PCA�˲�������V



function hat_x=cs_omp(y,T_Mat,m,s)
n=length(y);
hat_x=zeros(1,m);                                 %  ���ع�������(�任��)����                     
Aug_t=[];                                         %  ��������(��ʼֵΪ�վ���)
r_n=y;                                            %  �в�ֵ 
for times=1:s                                     %  ��������(ϡ����ǲ�����1/4)
% s=21
    product=abs(T_Mat'*r_n);
    
    [val,pos]=max(product);                       %  ���ͶӰϵ����Ӧ��λ��
    Aug_t=[Aug_t,T_Mat(:,pos)];                   %  ��������
    T_Mat(:,pos)=zeros(n,1);                      %  ѡ�е������㣨ʵ����Ӧ��ȥ����Ϊ�˼򵥽������㣩
    aug_x=(Aug_t'*Aug_t)^(-1)*Aug_t'*y;           %  ��С����,ʹ�в���С
    r_n=y-Aug_t*aug_x;                            %  �в�
    pos_array(times)=pos;                     %  ��¼���ͶӰϵ����λ��    
%     fprintf('size of aug_x is %dx%d\n',size(aug_x,1),size(aug_x,2))
%     fprintf('size of pos_array is %dx%d\n',size(pos_array,1),size(pos_array,2))
end
hat_x(pos_array)=aug_x;                           %  �ع�������
for i=1:s-1
    hat_x(pos_array(i))=0;
end
 



