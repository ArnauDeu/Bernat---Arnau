%% INFORMACIÓ PARTICIPANTS:
%
%   Bernat Berraquero - 1570716
%   Arnau Deu - 1564497
%

close all, clear all

%% TASCA 1 - SELECCIÓ i IMPORTACIÓ DEL DATASET 
% En aquesta part hem gestionat la carga de les dades
% i també com emmagatzemarem les dades. A més separem els frames 
% inicials que s'utilitzaràn pel train

cd C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE

%v = VideoReader("video1-1.mp4");
%v = VideoReader("video1-2.mp4");
%v = VideoReader("video1-3.mp4");
%v = VideoReader("video1-4.mp4");
%v = VideoReader("video1-5.mp4");
%v = VideoReader("video1-6.mp4");
%v = VideoReader("video1-7.mp4");
%v = VideoReader("video1-8.mp4");
%v = VideoReader("video1-9.mp4");
%v = VideoReader("video1-10.mp4");
%v = VideoReader("video1-11.mp4");
%v = VideoReader("video1-12.mp4");
%v = VideoReader("video1-13.mp4");
v = VideoReader("video1-14.mp4");

frames = read(v,[1,inf]);
tamany = size(frames);
copia = frames;
grup1 = zeros(tamany(1),tamany(2), tamany(4));
for i = 1:tamany(4)
   grup1(:,:,i) = rgb2gray(frames(:,:,:,i));
end

%% Homografia bird's eye --> birdeye
% Càlcul background de la homografia
base = copia(:,:,:,1);
imshow(base);
[x1, y1] = ginput(4);
close
x2 = [1;1;640;640];
y2 = [1;352;1;352];
M12 = [];   

for i=1:4
    M12 = [ M12;
    x1(i) y1(i) 1 0 0 0 -x2(i)*x1(i) -x2(i)*y1(i) -x2(i);
    0 0 0 x1(i) y1(i) 1 -y2(i)*x1(i) -y2(i)*y1(i) -y2(i)];  
end

[u,s,v] = svd( M12 );
H12 = reshape( v(:,end), 3, 3 )';
H12 = H12 / H12(3,3);
H21 = inv(H12);


memoria = zeros(12,3, 'double');


for i = 1:4
    imshow(base,[])
    [x, y, b] = ginput(1);
    close
    p = H12*[x y 1]';
    p = p/p(3);
    memoria(i,:) = p;
end


xplim = [floor(min(memoria(:,1))), ceil(max(memoria(:,1)))];
yplim = [floor(min(memoria(:,2))), ceil(max(memoria(:,2)))];

birdeye = uint8(zeros(abs(xplim(2)) + abs(xplim(1)) + 1, size(frames, 2), 3, size(frames, 4)));

[a1,a2, a3, a4] = size(birdeye);

for z = 1:a4
    for i = 1:a2
        for j = 1:a1
            
            % xp i jp generals en tota la iteracio
            xp = j + xplim(1) + 1;
            yp = i + yplim(1) + 1;

            % coloquem la imatge 1
            p = H21*[xp yp 1]';
            p = p/p(3);
            x = round(p(1));
            y = round(p(2));
            if(x > 0 && x <= a2 && y > 0 && y <= size(base,1))
                birdeye(j,i,:,z) = frames(y,x,:,z);
            end
        end
    end
end


grup2 = zeros(a1,a2, a4);
for i = 1:a4
   grup2(:,:,i) = rgb2gray(birdeye(:,:,:,i));
end

%% TASCA 2 - SISTEMA DE CAPTACIÓ DELS OBJECTES
% Agafem els 5 primers frames per fer el train i 
% el backgorund substracting

% EXTRACCIO AMB MANUAL 1

base = mean(grup1(:,:,1:10), 3);
base2 = mean(grup2(:,:,1:10), 3);
desv = std(grup1, [],  3);
desv2 = std(grup2, [],  3);


vermells = zeros(tamany(1),tamany(2), tamany(4));
vermells2 = zeros(a1, a2, a4);
substraccio = zeros(tamany(1),tamany(2), tamany(4));
substraccio2 = zeros(a1, a2, a4);

alpha = 1;
beta = 47;



for g = 1:tamany(4)
    substraccio(:,:,g) = abs(base - grup1(:,:,g)) > (desv * alpha + beta);
    substraccio2(:,:,g) = abs(base2 - grup2(:,:,g)) > (desv2 * alpha + beta);
end

% EXTRET PER SEPARAR ELS OBJECTIUS DEL PROJECTE DE DINS DEL FOR --> [a,b,vermells(:,:,g)] = getverm(a, b, substraccio(:,:,g));





%% TASCA 3 - SISTEMA DE DETECCIÓ DE LA TRAJECTORIA I DEFINIR EL SEU RECORREGUT
%
% Basat en el centre de masses.
% Basat en la diferencia entre coordenades
a = 0;
b = 0;
p = [];
z2 = 0;
b2 = 0;
p2 = [];
for g = 1:tamany(4)
    [a,b,p, vermells(:,:,g), copia(:,:,1,g)] = getverm(a, b, p, substraccio(:,:,g),copia(:,:,1,g));
    [z2,b2,p2, vermells2(:,:,g), birdeye(:,:,1,g)] = getverm(z2, b2, p2, substraccio2(:,:,g),birdeye(:,:,1,g));
end


%% TASCA 4 - SISTEMA PER REPRESENTAR LA TRAJECTORIA SOBRE EL VÍDEO
%
% HEM ESTAT PENSANT FER LA INCORPORACIÓ PRÈVIA, A LA VEGADA QUE DETECTEM I
% DEFINIM LA TRAJECTÒRIA PER EVITAR ALTA REDUNDANCIA I REPETICIÓ DE BUCLES 
%   

vermellsfinal = zeros(tamany);
vermellsfinal2 = zeros(a1,a2,a3,a4);


for x = 1:a4
    if x ~= 1
        vermellsfinal(:,:,1,x) = vermellsfinal(:,:,1,x-1) + vermells(:,:,x);
        vermellsfinal2(:,:,1,x) = vermellsfinal2(:,:,1,x-1) + vermells2(:,:,x);
    else
        vermellsfinal(:,:,1,1) = vermells(:,:,1);
        vermellsfinal2(:,:,1,1) = vermells2(:,:,1);
    end
end
    
birdeye2 = incorporar(p2, birdeye);
copia2 = incorporar(p, copia);
[imtest2,birdeye3] = canvis_direccio(p2, birdeye2);
[imtest,copia2] = canvis_direccio(p, copia2);
%% TASCA FINAL - GUARDAT DEL VIDEO
%
%  Aquesta part simplement es utilitzada per generar el video final i aixi
%  fer un anàlisi de la solució obtinguda
%

videot = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_trajectoria.mp4','MPEG-4');
videot2 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_trajectoria2.mp4','MPEG-4');

open(videot);
open(videot2);

vermell = cast(vermellsfinal, 'uint8');
vermell2 = cast(vermellsfinal2, 'uint8');

writeVideo(videot, vermell);
writeVideo(videot2, vermell2);

close(videot);
close(videot2);


% part 1


videoc = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_compost.mp4','MPEG-4');
videoc2 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_compost2.mp4','MPEG-4');
videoc3 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_compost3.mp4','MPEG-4');
videoc4 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_compost4.mp4','MPEG-4');

open(videoc);
open(videoc2);
open(videoc3);
open(videoc4);

writeVideo(videoc, copia);
writeVideo(videoc2, copia2);
writeVideo(videoc3, birdeye);
writeVideo(videoc4, birdeye3);

close(videoc);
close(videoc2);
close(videoc3);
close(videoc4);


videof = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_final.mp4','MPEG-4');
videof2 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_final2.mp4','MPEG-4');
videof3 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_final3.mp4','MPEG-4');
videof4 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_final4.mp4','MPEG-4');

open(videof);
open(videof2);
open(videof3);
open(videof4);

fin = copia2 + vermell;
fin2 = birdeye3 + vermell2;

writeVideo(videof3, fin);
writeVideo(videof4, fin2);

imtest = im2uint8(imtest);
imtest2 = im2uint8(imtest2);

fin  =  fin + imtest;
fin2  =  fin2 + imtest2;

fin = fin + vermell;
fin2 = fin2 + vermell2;

writeVideo(videof, fin);
writeVideo(videof2, fin2);

close(videof);
close(videof2);

close(videof3);
close(videof4);

%% FUNCIONS DEL CODI

%FUNCIO 1 -> TASCA 3 --> EXTRACCIÓ DEL PUNT DEL CENTRE DE LA IMATGE

function [a,b,p,sortida,copia] = getverm(a, b,p,img,copia)
totalx = 0;
totaly = 0;
count = 0;
[v1,v2,v3,v4] = size(copia);
% CALCUL DEL CENTRE DE MASSES DE L'OBJECTE

for x = 1:v1
    for y = 1:v2
        if img(x,y) == 1
        totalx = totalx + x;
        totaly = totaly + y;
        count = count + 1;
        end
    end
end

sortida = zeros(v1, v2);

% DETECCIÓ D'OBJECTE EN IMATGE.
x = 0;
y = 0;

if count ~= 0
    x = round(totalx/count);
    y = round(totaly/count);
    
    if a == 0
        a = x;
        b = y;
    
        return
    end
    
    while (x ~= a || y ~= b )
        sortida(a,b) = 255;
        copia(a,b) = 255;   
        if (x ~= a)
            res_x = x - a;
            res_x = res_x / abs(res_x);
            a = a + res_x;
            if (y ~= b)
                res_y = y - b; 
                res_y = res_y / abs(res_y);
                b = b + res_y;
            end
        end
        
        if (y~=b)
            res_y = y - b; 
            res_y = res_y / abs(res_y);
            b = b + res_y;
        end
    end
else 
    a = 0;
    b = 0;     
end
p = [p;[x,y]];
end

function matriu = incorporar(p, matriu)
    [pa1, pa2] = size(p);
    for i = 1:pa1
        if p(i) ~= 0
            matriu(:,:,:,i) = insertShape(matriu(:,:,:,i), "Circle", [p(i,2),p(i,1) , 30]);
        end
    end
end



function [img, matriu] = canvis_direccio(p, matriu)
    signe1 = 0;
    signe2 = 0;
    tam = size(matriu);
    img = zeros(tam(1),tam(2), tam(3));
    anterior = [0, 0];
    [pa1, pa2] = size(p);
    for i = 1:pa1
        if p(i) ~= 0
            if anterior(1) ~= 0
               if signe1 == 0
                   signe1 = (p(i,1) -  anterior(1)) / abs(p(i,1) -  anterior(1));
                   signe2 = (p(i,2) -  anterior(2)) / abs(p(i,2) -  anterior(2));
               else
                   signen1 = (p(i,1) -  anterior(1)) / abs(p(i,1) -  anterior(1));
                   signen2 = (p(i,2) -  anterior(2)) / abs(p(i,2) -  anterior(2));

                   if signe1 ~= signen1 || signe2 ~= signen2
                       matriu(:,:,:,i) = insertShape(matriu(:,:,:,i), "FilledCircle", [p(i,2),p(i,1) , 15]);
                       img = insertShape(img, "FilledCircle", [p(i,2),p(i,1) , 15]);
                       signe1 = signen1;
                       signe2 = signen2;
                   end
               end
            end

            anterior = p(i, :);
            
        end
    end
            

end

