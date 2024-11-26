%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 音響MRを作る: 
% BRIRを検出する．3点ピンポイント
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 立体音響化する音源の読み込み %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[s, fs] = audioread("こんにちは.wav");  % 立体音響化する音源
s = s./max(abs(s))*0.1; % 音量を下げる 
[s0, fs2] = audioread("impulse06.wav"); % 廊下


%%%%%%%%%%%%%%%%%%%%%%%%%
%  インパルス応答の検出 %
%%%%%%%%%%%%%%%%%%%%%%%%%
ImpLen = 0.5*fs;         % 最終的なインパルス応答の長さを0.4秒にする
Imp=[];                  % インパルス応答の格納用変数
posi = [];               % インパルスの場所を格納する変数 廊下
N = length(s0);          % サンプル数
for i=20:N               % 毎サンプルずつ調べる
    x1=0; x2=0;
    max1= abs(s0(i-10,1));    % 1chの最大振幅と位置を取得
    max2= abs(s0(i-10,2));    % 2chの最大振幅と位置を取得
    if max1 == max(max1, max2) % 音源が1ch寄りの時
        x1 = s0(i-10,1)-s0(i-19,1); % 3点を約0.0002sの間隔でとる
        x2 = s0(i,1)-s0(i-10,1); 
    else % 2ch寄りのとき
        x1 = s0(i-10,2)-s0(i-19,2); % 3点を約0.0002sの間隔でとる
        x2 = s0(i,2)-s0(i-10,2); % 音源が長いときは，5sくらい
    end
    if x1 * x2  <= -0.4
        pos = i -10; % 頂点のポジション
        if ~isempty(posi) && abs(pos - posi(length(posi))) < 1.0 * fs 
            % 1秒以内に同じ音量のインパルスを検出したら，
            % その前のインパルスを消してインパルスではないようにする
            continue
        end
        posi = [posi pos]; %ポジションを覚えておく
        st = max([pos-fs/20, 1]);           % 少し手前をインパルス応答の開始位置とする
        en = min(st+ImpLen, length(s0(:,1))); % 0.4秒間のインパルス応答を採用
        yin=s0(st:en,:);                      % 抽出したインパルス応答
        if(length(yin(:,1))<ImpLen)          % 長さが足りないときは0を追加する
            L = ImpLen - length(yin(:,1))+1;
            yin=[yin;zeros(L,2)];
        end
        yin=yin/norm(yin);             % 大きさを正規化する
        Imp=[Imp yin];          % インパルス応答を格納
    end
end
posNum = length(posi);
x = input(posNum +" こ目のBRIRを検出");
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 取得したインパルス応答の数だけ音源を分割する %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
K = length(posi);                             % K個のインパルス応答を取得する
Len = length(s);                 % 1区間の長さ

%%%%%%%%%%%%%%%%%%%%
% 立体音響の作成   %
%%%%%%%%%%%%%%%%%%%%
out1=s0(:,1); out2=s0(:,2);                      % 2ch出力信号の初期化_廊下
sz = size(out1);
for i=1:K
    %% 左
    A = conv(s, Imp(:,2*i-1)); % 畳み込む_廊下
    
    b = zeros(sz); % 長さを合わせる
    b(posi(1,i)+fs:posi(1,i)+fs+length(A)-1,:) = A; % 大きさをoutに揃える
    %out1 = out1 + conv(DivS(:,i), Imp(:,2*i-1)); % 1ch output
    if(length(out1)<length(b))          % 長さが足りないときは0を追加する
        b1 = b;   
        b = b1(1:length(out1),:);
    end
    out1 = out1 + b; % 1ch output
    %% 右
    B = conv(s, Imp(:,2*i)); %畳み込む
  
    b = zeros(sz); % 長さを合わせる
    b(posi(1,i)+fs:posi(1,i)+fs+length(B)-1,:) = B; 
    if(length(out2)<length(b))          % 長さが足りないときは0を追加する
        b2 = b;
        b = b2(1:length(out2),:);
    end
    out2 = out2 + b;   % 2ch output
end
out = [out1,out2];                 % 2ch立体音響
out = out./max(abs(out))*0.8;      % 全体の振幅を調整
disp('Start Writing.');            % 書き出し開始
audiowrite('./rslt_mr6_hello/output.wav',out,fs); % 廊下で廊下のBRIR
disp('End of Writing.');           % 書き出し終わり
%disp("3D sound play");
%sound(out,fs);                    % 立体音響を再生する
