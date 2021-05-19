%% INFORMACIÓ PARTICIPANTS:
%
%   Bernat Berraquero - 1570716
%   Arnau Deu - 1564497
%

close all, clear all

%% TASCA 1 - SELECCIÓ i IMPORTACIÓ DEL DATASET 
% En aquesta part hem gestionat la carga de les dades
% i també com emmagatzemarem les dades.
%

cd C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE

v = VideoReader("video2.mp4");

frames = read(v,[1,inf]);
%automatitazició
siz = size(frames);
sip = [siz(1);siz(2);siz(4)];

grup1 = zeros(sip);
copia = zeros(siz);

for i = 1:siz(4)
   copia(:,:,:,i) = frames(:,:,:,i);
   grup1(:,:,i) = rgb2gray(frames(:,:,:,i));
end


%% TASCA 2 - SISTEMA DE CAPTACIÓ DELS OBJECTES
%
%

% EXTRACCIO AMB MANUAL 1

mitjana = mean(grup1, 3);
desv = std(grup1, [],  3);


vermells = zeros(sip);
substraccio = zeros(sip);

alpha = 1;
beta = 27;



for g = 1:siz(4)
    substraccio(:,:,g) = abs(mitjana - grup1(:,:,g)) > (desv * alpha + beta);
end

% EXTRET PER SEPARAR ELS OBJECTIUS DEL PROJECTE DE DINS DEL FOR --> [a,b,vermells(:,:,g)] = getverm(a, b, substraccio(:,:,g));


%% TASCA 3 - SISTEMA DE DETECCIÓ DE LA TRAJECTORIA I DEFINIR EL SEU RECORREGUT
%
% Basat en el centre de masses.
% Basat en la diferencia entre coordenades
a = 0;
b = 0;
p = [];

for g = 1:siz(4)
    [a,b,p, vermells(:,:,g), copia(:,:,1,g)] = getverm(a, b, p, substraccio(:,:,g),copia(:,:,1,g));
end



%% TASCA 4 - SISTEMA PER REPRESENTAR LA TRAJECTORIA SOBRE EL VÍDEO
%
% HEM ESTAT PENSANT FER LA INCORPORACIÓ PRÈVIA, A LA VEGADA QUE DETECTEM I
% DEFINIM LA TRAJECTÒRIA PER EVITAR ALTA REDUNDANCIA I REPETICIÓ DE BUCLES 
%

vermells2 = zeros(siz);


for x = 1:siz(4)
    if x ~= 1
        vermells2(:,:,1,x) = vermells2(:,:,1,x-1) + vermells(:,:,x);
    else
        vermells2(:,:,1,1) = vermells(:,:,1);
    end
end
    
%% TASCA 5 - SISTEMA DE GENERACIÓ DE LA TRAJECTÒRIA
%
%

moviment = [p(1);p(2); p(3)];
tamany = size(p);

%llistes de prediccions 
prediccio = zeros(tamany);
prediccio(1:3,:) = p(1:3,:);

for x = 4:tamany(1)
    
    d1 = [moviment(2:1)-moviment(1:1) ; moviment(2:2)-moviment(1:2)];
    d2 = [moviment(3:1)-moviment(2:1) ; moviment(3:2)-moviment(2:2)];
    
    prox_valors = [d2(1)-d1(1);d2(2)-d2(2)];
    
    next = moviment(3,1);
    
    %distancies anteriors
    moviment = [moviment(x-3:x-1,:);p(x, :)];
end


%% TASCA FINAL - GUARDAT DEL VIDEO
%
%  Aquesta part simplement es utilitzada per generar el video final i aixi
%  fer un anàlisi de la solució obtinguda
%

video = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_s.mp4','MPEG-4');
video2 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_p.mp4','MPEG-4');
video3 = VideoWriter('C:\Users\ernu1\Desktop\Universitat\PSIV\PROJECTE\video_c.mp4','MPEG-4');
open(video);
open(video2);
open(video3);

img = zeros(sip(1), sip(2));
img2 = zeros(sip);
img3 = zeros(sip); 

for i =1:374
    img = substraccio(:,:,i);
    img2 = vermells2(:,:,:,i)/255;
    img3 = copia(:,:,:,i)/255;
    writeVideo(video, double(img));
    writeVideo(video2, img2);
    writeVideo(video3, img3);
end
    
close(video);
close(video2);
close(video3);

%% FUNCIONS DEL CODI

%FUNCIO 1 -> TASCA 3 --> EXTRACCIÓ DEL PUNT DEL CENTRE DE LA IMATGE

function [a,b,p,sortida,copia] = getverm(a, b,p,img,copia)
totalx = 0;
totaly = 0;
count = 0;
% CALCUL DEL CENTRE DE MASSES DE L'OBJECTE
siz = size(img);
for x = 1:siz(1)
    for y = 1:siz(2)
        if img(x,y) == 1
        totalx = totalx + x;
        totaly = totaly + y;
        count = count + 1;
        end
    end
end

sortida = zeros(siz);

% FEFINICIÓ TRAJECTÒRIA .
if count ~= 0
    x = round(totalx/count);
    y = round(totaly/count);
    
    % GUARDEM ELS PUNTS PER DESPRES GENERAR LA PREDICCIÓ
    p = [p;[x,y]];
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
end


