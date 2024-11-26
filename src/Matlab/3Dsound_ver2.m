%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BRIRを検出し，音響MRを作成する
% BRIRの検出は現在の信号からbuff秒間の
% 最大値・最小値・現在の信号の3点を利用
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
[s, fs] = audioread("こんにちは.wav");  % 立体音響化する音源
s3d=s*1.0;

[s, fs] = audioread("impulse_te_5.wav");   % 生活音
buff = fs*0.5;
Len = length(s);                        % 信号の長さ
D   = 10;                               % 信号の変化量(傾き)を調べる範囲(片側)
Th  = 0.4;                              % 傾きのしきい値 
cnt = 0;                                % BRIR判別用カウンタ
HFB_max = 0;                            % 傾きの最大値を初期化
HFB_now = 0;                            % 現在の傾きを初期化
num=0;                                  % BRIRの検出数
x = zeros(buff,2);                      % 1秒間の入力ベクトル
time_index=[];                          % BRIRの時刻記録
BRIR=[];                                % BRIR波形記録
y=s;                                    % 出力＝入力
n=0;                                    % 3D Soundの時刻管理
flg=0;
Len3D=0;
x_s  = zeros(buff,2);                   % xの2乗
x_ss = 0;                               % x(Lch,Rch)の2乗和
brir = zeros(buff,2);                   % 検出したxのエネルギー
HBias = zeros(3,Len);                   % 検出したxのエネルギー

for i=1:Len
    x(1,:)   = s(i,:);                  % 現在の入力信号
    
    % 現在の信号を含むbuff秒間をBRIRであると仮定する
    HF1 = x(D,1) - min( x(2:D,1) );     % 前方の高さ変化1ch
    HB1 = x(D,1) - min( x(D+1:2*D,1) ); % 後方の高さ変化1ch
    HF2 = x(D,2) - min( x(2:D,2) );     % 前方の高さ変化2ch
    HB2 = x(D,2) - min( x(D+1:2*D,2) ); % 後方の高さ変化2ch
    HFB_now  = max(HF1*HB1, HF2*HB2);   % 現在の信号の傾き
    HBias(1,i) = HFB_now;
    HBias(2,i) = cnt;
    HBias(3,i) = flg;
    
    % 信号がBRIRかどうかを判定する
    if flg==0
    if HFB_now>=Th                      % 傾きがしきい値を超えた？
        cnt = 0;                        % カウンタをリセット
        HFB_max = HFB_now;              % 傾きの最大値を更新
    else if HFB_max==0                  % HFB_maxが初期値のまま？
            cnt = 0;                    % カウンタをリセット
         else                           % 現在の傾きがしきい値未満ならば
            cnt = cnt+1;                % カウントアップ
         end                             
    end
    
    % BRIRだった場合，検出した信号を利用して立体音響を作成
    if (cnt >= buff-441)                  % カウンタ1秒弱経過？
        x_s  = x.^2;
        x_ss = sum(x_s,"all");
        brir = x ./ x_ss .* 2;
        Add_3D = [];
        BRIR = [BRIR flip(brir)];           % 観測信号をBRIRとする
        Add_L = conv(s3d, BRIR(:,num*2+1)); % 3D Sound Lch
        Add_R = conv(s3d, BRIR(:,num*2+2)); % 3D Sound Rch
        Add_3D = [Add_L, Add_R];            % 3D Stereo Sound
        Add_3D = Add_3D/max(Add_3D(:))*0.5;
        Len3D = length(Add_L);
        %Len3D = fs;
        num=num+1;                      % BRIRの検出数を＋1
        time_index = [time_index; HFB_max, i]; % BRIRの終了時刻を記録
        HFB_max=0;                      % 傾きの最大値を初期化
        cnt  = 0;                       % カウンタをリセット
        n=1;                            % 3D sound time index
        flg=1;                          % 3D sound addition flag
    end
    end
    x(2:end,:)=x(1:end-1,:);            % 1秒間の入力ベクトルをシフト

    if flg==1                           % flag=1のとき
        y(i,:)=s(i,:)+Add_3D(n,:);      % 3D Sound Addition
        n=n+1;                          % 3D Sound時刻＋1
    end
    if n>=Len3D                         % 3D音響付加が2秒を超えると初期状態に戻す
        %flg=0;
        n=0;
    end
    if n>=Len3D/2                        % 3D音響付加が2秒を超えると初期状態に戻す
        flg=0;
    end
end

%% 入力と出力をwavファイルに保存
%Add_L2 = conv(s3d, BRIR(:,3)); % 3D Sound Lch
%Add_R2 = conv(s3d, BRIR(:,4)); % 3D Sound Rch
%Add_3D2 = [Add_L2, Add_R2];        % 3D Stereo Sound
%Add_3D2 = Add_3D2/max(Add_3D2(:))*0.5;
%BRIR_out = [BRIR(:,3), BRIR(:,4)];
audiowrite('input.wav',  s, fs);
audiowrite('output.wav', y, fs);     


% 検出したBRIRをプロット
figure(1);clf;
for i=1:num*2
    subplot(num, 2, i);
    plot(BRIR(:,i));
end
figure(2);clf;
subplot(5,1,1);
plot(s);
subplot(5,1,2);
plot(HBias(1,:));
subplot(5,1,3);
plot(HBias(2,:));
subplot(5,1,4);
plot(HBias(3,:));
subplot(5,1,5);
plot(y);
