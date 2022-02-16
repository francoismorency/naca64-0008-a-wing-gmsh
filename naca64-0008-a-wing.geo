Include "naca-64A008-coordinate.geo";
Geometry.Tolerance = 0.1e-8;
Geometry.MatchMeshTolerance = 1e-10;
Geometry.AutoCoherence=0;

//Fonction coord permettant de créer la liste des coordonnées des points
//il y a 589 points dans le fichier coordonnée
Function coord_xy
	For i In {1:589}
		coord[]=Point{i};
		x[i-1]=coord[0];
		y[i-1]=coord[1];
	EndFor
Return

//Fonction left_wing permettant de créer un profil en profondeur

Function left_wing
	ct=0;
    //il y a deux sections une a la racine de l'aile,
    //une autre a l'extrémité
	step_y=demi_span/(nb_sec-1);
    //définir un taille par défaut pour le maillage de surface
    //trois regions: leading edge x<0.1, milieu 0.1<x<0.95, trailing edge x>0.95
    //nous gardons la même taille partout
    taille=le;
	For j In {1:nb_sec-1}
		ct=ct+step_y;
		For i In {0:588}
			p=newp;
			If (x[i]<=0.1)
				Point(p)={x[i],y[i],-ct,taille};
			EndIf
			If (x[i]>0.1 && x[i]<0.95 )
				Point(p)={x[i],y[i],-ct,taille};
			EndIf
			If (x[i]>=0.95 )
				Point(p)={x[i],y[i],-ct,taille};
			EndIf
		EndFor
	EndFor
Return

//Fonction Translate_sec permettant de translater les différents sections de l'ailes pour créer l'aigle en flèche
//avec les 29.1° par rapport au bord d'attaque.

Function Translate_sec
//section à la racine points de 1 à 589
//section à l'extrémité points de 590 à 1178
	x_translate= demi_span/(nb_sec-1)*Tan(sweep);
	For j In {1:nb_sec-1}
		For i In {(589*j)+1:(589*j)+589}
			Translate {x_translate*j,0,0}{Point{i};}
		EndFor
	EndFor		
Return			

//Fonction coord_ch_quart permettant de faire la rotation des sections selon le quart de leur chord pour créer le 
// twist de -4° de l'aile

Function coord_ch_quart
	step_z=demi_span/(nb_sec-1);
	step_angle=(twist_angle)/(nb_sec-1);
	For j In {1:nb_sec-1}
		tt[]=Point{(589*j)+1};
		ttt[]=Point{(589*j)+589};
		ycar=ttt[1]-tt[1];
		xcar=ttt[0]-tt[0];
        //l'angle de twist est réparti linéairement
        //l'angle de twist est de 0 deg à la racine
        //l'angle de twist est de 0 deg à l'extrémité
		angg=Atan(ycar/xcar);
        //la rotation se fait par rapport au quart de la corde
        // posx, posy coordonnées du quart de la corde
		posy=0.25*(1-rt*j)*root_ch*Sin(angg);
		posx=0.25*(1-rt*j)*root_ch*Cos(angg);
		For i In {(589*j)+1:(589*j)+589}
				Rotate {{0,0, 1},{posx,posy,tt[2]},step_angle*j} {Point{i};}
		EndFor
	EndFor
Return

//Fonction scale permettant de mettre à l'echelle chaque sectionde l'aile

Function scale
	step_z=demi_span/(nb_sec-1);
    //la mise à l'échelle de la corde d'épend de l'effilement 
    // et de la position le long de l'envergure 
	rt=(1-taper_ratio)/(nb_sec-1);
	For j In {1:nb_sec-1}
		tt[]=Point{(589*j)+1};
		For i In {(589*j)+1:(589*j)+589}
			Dilate {{tt[0],tt[1],tt[2]},(1-rt*j)*root_ch}{Point{i};}
		EndFor
	EndFor
Return

//Fin des fonctions

//
//Code principal aile naca-64A008
//
//configuration de la moitié d'une aile naca-64A008
//grandeurs physiques de l'aile données en pouce et converties en pieds
demi_span=60.96*0.0254; //la moitié de l'envergure
root_ch=25.2*0.0254; //la chord à la racine en inch
nb_sec=2; //le nombre de section de l'aile voulu
sweep=29.1*Pi/180.; //l'angle de la flèche
taper_ratio=0.62; //le ratio entre la longueur de la chord du bout d'aile divisé par celle des la racine
twist_angle=0*Pi/180; //l'angle de rotation de l'aile
//
// info pour le maillage lié à la géométrie
// définir une grandeur et une grandeur d'élément caractéristique
lcar=root_ch;
le=lcar/50;
ld=3*lcar;


//Creation de l'aile 


Call coord_xy;
Call left_wing;

Call scale;
xpt1[]=Point{1};
Dilate {{xpt1[0], xpt1[1], xpt1[2]},root_ch}{Point{1:589};} //mettre à l'échelle la première section d'aile
Call coord_ch_quart; //rotation pour le twist
Translate {-root_ch/4,0,0}{Point{1:(589*(nb_sec-1))+589};}//mettre toute les section au quart de la chord racine

Call Translate_sec; //création de l'aile en flèche
//Call coord_ch_quart; //rotation pour le twist
// rotation pour avoir l'axe y dans la direction de l'envergure de l'aile
xpt1[]=Point{1};
Rotate {{0, 0, 1}, {0, 0, 0}, -Pi} { Point{1:(589*(nb_sec-1))+589}; }
xpt1[]=Point{1};
Rotate {{0,1,0}, {0, 0, 0}, -Pi} { Point{1:(589*(nb_sec-1))+589}; }
//xpt1[]=Point{1};
Rotate {{1, 0, 0}, {0, 0, 0}, -Pi/2} { Point{1:(589*(nb_sec-1))+589}; }
//
// creation du profil à la racine
Spline(1)={1:294};
Spline(2)={294,589:296,1};
Curve Loop(1) = {2,1};
// creation du profil à l'extremite
Spline(4)={(589*(nb_sec-1)+1):((589*(nb_sec-1)+1)+293),((589*(nb_sec-1)+1)+588)};
Spline(5)={((589*(nb_sec-1)+1)+588),(589*(nb_sec-1)+1)+587:((589*(nb_sec-1)+1)+297),(589*(nb_sec-1)+1)};
Curve Loop(2) = {5,4};
//ligne du bord de fuite
spl_7[]={};
For i In {0:nb_sec-1}
	spl_7[i]=((589*i+1)+588);
EndFor
Spline(7)={spl_7[]};
//ligne du bor d'attaque
spl_8[]={};
spl_9[]={};
For i In {0:nb_sec-1}
	spl_9[i]=589*i+1;
EndFor
Spline(9)= {spl_9[]};
//creation des boucles pour la surface inferieure et superieure 
Curve Loop(3) = {7, -4, -9, 1};
Curve Loop(4) = {7, -2, -9, 5};
//
//surface et création volume
Plane Surface(1)={2};
Surface (2) = {3};
Surface (3) = {4};
Surface loop(1)={1,2,3};
Surface Loop(2) = {3, 35, 2, 1};


// ld est la taille des elements sur la  frontiere externe
pt_cyl[]={};
pt_rec[]={};
list_l[]={};
p=newp;
pt_cyl[0]=p;
Point(p)={0,0,0,ld};
p=newp;
pt_cyl[1]=p;
Point(p)={-20,0,0,ld};
p=newp;
pt_cyl[2]=p;
Point(p)={0,0,20,ld};
p=newp;
pt_cyl[3]=p;
Point(p)={20,0,0,ld};
p=newp;
pt_cyl[4]=p;
Point(p)={0,0,-20,ld};
c=newc;
list_l[0]=c;
Circle(c) = {pt_cyl[4],pt_cyl[0],pt_cyl[1]};
c=newc;
list_l[1]=c;
Circle(c) = {pt_cyl[1],pt_cyl[0],pt_cyl[2]};
c=newc;
list_l[2]=c;
Circle(c) = {pt_cyl[2],pt_cyl[0],pt_cyl[3]};
c=newc;
list_l[3]=c;
Circle(c) = {pt_cyl[3],pt_cyl[0],pt_cyl[4]};
cl=newll;
Curve Loop(cl) = {list_l[1],list_l[2],list_l[3],list_l[0]};
far[]= Extrude {0.000000,20,0.0000000} { Line{list_l[0]:list_l[3]}; };

//création de la surface de la symmétrie
Coherence;
//+
Curve Loop(15) = {19, 23, 27, 15};
//+
Plane Surface(31) = {15};
//+
Plane Surface(32) = {1, 14};
//+
Surface Loop(3) = {2, 1, 3, 32, 18, 22, 26, 30, 31};
//+
Volume(1) = {3};
//+
Physical Surface("FARFIELD", 33) = {22, 18, 31, 30, 26};
//+
Physical Surface("SYMMETRY", 34) = {32};
//+
Physical Surface("WING", 35) = {4, 2, 3, 1};
//+
Physical Volume("FLOW", 36) = {1};
Coherence;

// distance leading edge
x2=Point{590};
x1=Point{1};
ommega = Atan((x2[0]-x1[0])/1.524);
gamma = Atan((x2[0]-x1[0])/(x2[2]-x1[2]));
teta =  Atan((x2[2]-x1[2])/1.524);
d1 = 0.6;
linco=(1-d1*(0.4-1)/1.524)*0.1;
d2 = x1[0]-d1*ommega;
d3 = x1[2]-d1*teta;
env=demi_span;
ch=root_ch;
d4= 0.08;
d5 = x2[0]+d4*ommega;
d6 = x2[2]+d4*teta;
env=demi_span;
ch=root_ch;

env=demi_span;
ch=root_ch;
lde=lcar/97;
fact=50;
rt=0.4;
//
// The field definitions are used for the mesh
//+
Field[1] = Frustum;
//+
Field[1].InnerR1 = linco*lcar;
//+
Field[1].InnerR2 = linco*lcar*rt;
//+
Field[1].InnerV1 = lde;
//+
Field[1].InnerV2 = lde*rt;
//+
Field[1].OuterR1 = ld;
//+
Field[1].OuterR2 = ld*rt;
//+
Field[1].OuterV1 = fact*lde;
//
Field[1].OuterV2 = fact*lde*rt;
//+
Field[1].X1 = d2;
//+
Field[1].X2 = d5;
//+
Field[1].Y1 = -d1;
//+
Field[1].Y2 = 1.524+d4;
//+
Field[1].Z1 = d3;
//+
Field[1].Z2 = d6;
fact_2=0.6;

Field[2] = Frustum;
//+
Field[2].InnerR1 = 0;
//+
Field[2].InnerR2 = 0;
//+
Field[2].InnerV1 = lde*fact_2;
//+
Field[2].InnerV2 = lde*fact_2*rt;
//+
Field[2].OuterR1 = linco*lcar;
//+
Field[2].OuterR2 = linco*lcar*rt;
//+
Field[2].OuterV1 = lde;
//
Field[2].OuterV2 = lde*rt;
//+
Field[2].X1 = d2;
//+
Field[2].X2 = d5;
//+
Field[2].Y1 = -d1;
//+
Field[2].Y2 = 1.524+d4;
//+
Field[2].Z1 =d3;
//+
Field[2].Z2 = d6;
//
x2=Point{1178};
x1=Point{589};
ommega = Atan((x2[0]-x1[0])/1.524);
gamma = Atan((x2[0]-x1[0])/(x2[2]-x1[2]));
teta =  Atan((x2[2]-x1[2])/1.524);
d1 = 0.6;
linco=(1-d1*(0.4-1)/1.524)*0.06;
d2 = x1[0]-d1*ommega;
d3 = x1[2]+d1*teta;
d4= 0.08;
d5 = x2[0]+d4*ommega;
d6 = x2[2]-d4*teta;
//
ldt=lcar/90;
fact_4=45;
Field[3] = Frustum;
//+
Field[3].InnerR1 = linco*lcar;
//+
Field[3].InnerR2 = linco*lcar*rt;
//+
Field[3].InnerV1 = ldt;
//+
Field[3].InnerV2 = ldt*rt;
//+
Field[3].OuterR1 = ld;
//+
Field[3].OuterR2 = ld;
//+
Field[3].OuterV1 = ldt*fact_4;
//
Field[3].OuterV2 = ldt*fact_4*rt;
Field[3].X1 = d2;
//+
Field[3].X2 = d5;
//+
Field[3].Y1 = -d1;
//+
Field[3].Y2 = 1.524+d4;
//+
Field[3].Z1 = d3;
//+
Field[3].Z2 = d6;
Field[4] = Frustum;
fact_3=0.5625;
//+
Field[4].InnerR1 = 0;
//+
Field[4].InnerR2 = 0;
//=
Field[4].InnerV1 = lde*fact_3;
//+
Field[4].InnerV2 = lde*fact_3*rt;
//+
Field[4].OuterR1 = linco*lcar;
//+
Field[4].OuterR2 = linco*lcar*rt;
//+
Field[4].OuterV1 = ldt;
//
Field[4].OuterV2 = ldt*rt;
//+
Field[4].X1 = d2;
Field[4].X2 = d5;
//+
Field[4].Y1 = -d1;
Field[4].Y2 = 1.524+d4;
Field[4].Z1 = d3;
Field[4].Z2 = d6;


Field[5] = Distance;
Field[5].CurvesList = {4,5};
Field[5].NumPointsPerCurve = 90;
Field[6] = Threshold;
Field[6].InField = 5;
Field[6].SizeMin = lcar*0.4/80;
Field[6].SizeMax = ld;
Field[6].DistMin = 2*lcar*0.4/80;
Field[6].DistMax = lcar;

Field[7] = Distance;
Field[7].CurvesList = {1,2};
Field[7].NumPointsPerCurve = 80;
Field[8] = Threshold;
Field[8].InField = 7;
Field[8].SizeMin = lcar/80;
Field[8].SizeMax = ld;
Field[8].DistMin = 2*lcar/80;
Field[8].DistMax = lcar;
Field[15] = Min;
Field[15].FieldsList = {1,2,3,4,6,8};
Background Field = 15;




