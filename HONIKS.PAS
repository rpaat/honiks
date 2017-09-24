Program HONIKS;
uses crt;
const vrv=lightgray;
      edetabel='parimad.hon';
      avaekraan='honiks.hon';
type elektron=record
              e:char;
              x,y:integer;
              dx,dy:shortint;
              vrv:word;
              end;
     laeng=array[1..100] of elektron;
     s=(yles,alla,paremale,vasakule,paigal);
     ekrmas=array[1..50,1..80,1..2] of byte;
     isik=record
            nimi:string[15];
            tase:word;
            punkte:longint;
            end;
     parimadisikud=array[1..10] of isik;

var ekr:ekrmas absolute $b800:0;
    abi,abiavaekraan:ekrmas;
    i,n:integer;
    elekter:laeng;
    elusid,samm,puudu,mitu:integer;
    seisund:s;
    joon,mus,lo,elu:boolean;
    jx,jy:integer;
    alus:byte;
    summa:longint;
    c1,c2:char;
    parimad:parimadisikud;

Procedure Kaotakursor;assembler;
asm
    mov ah,01h
    mov ch,20h
    int 10h
end;

Procedure Tekitakursor;assembler;
asm
    mov ah,01h
    mov ch,1eh
    mov cl,1fh
    int 10h
end;

function loesqna(x,y,maxpikkus:integer):string;
var uustekst:string;
    kursor:integer;
    pikkus:integer;
    lopp:boolean;
    mrk, m: char;
begin
  textcolor(white);
  textbackground(blue);
  TekitaKursor;
  uustekst:='';
  pikkus:=0;
  kursor:=pikkus+1;
  lopp:=true;
  gotoxy(x,y);
  write(uustekst,' ':maxpikkus-pikkus+1);
  gotoxy(x,y);
  while lopp do
    begin
      mrk:=readkey;
      if keypressed then m:=readkey;
      case mrk of
        ' '..'љ','д','е': begin
                    if kursor<=maxpikkus then
                      begin
                        inc(pikkus);
                        uustekst:=copy(uustekst,1,kursor-1) + mrk +
                                  copy(uustekst,kursor,pikkus-kursor+1);
                        if pikkus>maxpikkus then
                          begin
                            delete(uustekst,maxpikkus+1,1);
                            dec(pikkus);
                          end;
                        inc(kursor);
                        gotoxy(x,y);
                        write(uustekst,' ':maxpikkus-pikkus+1);
                        gotoxy(x+kursor-1,y);
                      end;
                  end;
        #8     : begin                          {Backspace}
                    if kursor<>1 then
                      begin
                        dec(kursor);
                        delete(uustekst,kursor,1);
                        dec(pikkus);
                        gotoxy(x,y);
                        write(uustekst,' ':maxpikkus-pikkus+1);
                        gotoxy(x+kursor-1,y);
                      end;
                  end;
        #13 :begin                              {Enter}
               lopp:=false;
             end;
        end;    {case mrk}
    end;
  loesqna:=uustekst;
  KaotaKursor;
end;

Function Seavarv(v:integer):word;
begin
  case v of
    8:seavarv:=green;
    1..16:seavarv:=v;
    end;
end;

Procedure arvutapuudu;
begin
  {puudu:=3600-200*mitu;}
  puudu := 1500 + (13600 div (mitu + 5));
end;

(* Teeme uue edetabeli, kui vaja... *)
Function FileExists(FileName: string): boolean;
var
  F: file;
begin
  {$I-}
  Assign(F, edetabel);
  FileMode := 0;  { Set file access to read only }
  Reset(F);
  Close(F);
  {$I+}
  FileExists := (IOResult = 0) and (FileName <> '');
end;

Procedure KirjutaParimadKettale;
var
  f: file;
begin
  assign(f, edetabel);
  rewrite(f,1);
  blockwrite(f,parimad,sizeof(parimad));
  close(f);
end;

Procedure LoeParimadKettalt;
var
  f: file;
  i, viga: integer;
begin
  assign(f, edetabel);
  {$I-}
  FileMode := 0; {avame ReadOnly'ga}
  reset(f,1);
  {$I+}
  viga := IOResult;
  if (Viga = 0) then
    begin
      blockread(f,parimad,sizeof(parimad));
      {read(f,parimad);}
      close(f);
    end
  else
    begin
      {teeme uue edetabeli}
      for i:=1 to 10 do
        begin
          parimad[i].nimi := '';
          parimad[i].punkte := -1;
        end;
      assign(f, edetabel);
      rewrite(f,1);
      blockwrite(f,parimad,sizeof(parimad));
      close(f);
    end;
end;

Procedure TooParimadEkraanile;
var
  i, viga: integer;
begin
  KaotaKursor;
  ekr := abiavaekraan;
  TextColor(Black);
  TextBackground(Cyan);
  gotoxy(48, 31);
  write('Nimi           Tase Punkte');

  (* Viime edetabeliandmed ekraanile *)
  for i:=1 to 10 do
    begin
      gotoxy(47, 31 + i);
      if parimad[i].punkte > 0 then         {nullipoisid tabelisse ei p„„se}
        write(parimad[i].nimi,' ':(16-length(parimad[i].nimi)), parimad[i].tase:4, parimad[i].punkte:9);
    end;

  (* Viimase tulemuse n„itamine *)
  if mitu > 0 then
    begin
      TextColor(Black);
      TextBackground(Magenta);
      GotoXY(63, 45);
      Write(mitu - 2: 4, Summa: 9);
    end;

  TextColor(White);
  TextBackground(Blue);
  GotoXY(14, 36);
  Write('TЃhik - alustab');
  GotoXY(14, 37);
  Write('ESC - katkestab');
end;

Procedure KontrolliEdetabel;
var
  i,j: integer;
begin
  (* Kui summa on suurem, kui esimesel viimasel edetabelis siis l„heb sisse *)
  if (summa > 0) and (summa > parimad[10].punkte) then
    begin
      i := 10;
      while (i > 1) and (summa > parimad[i-1].punkte) do
        begin
          parimad[i] := parimad[i-1];
          parimad[i-1].nimi := '';
          parimad[i-1].punkte := summa;
          parimad[i-1].tase := mitu - 2;
          TooParimadEkraanile;
          if mus then
            begin
              delay(100);
              sound(1500 - i*100);
              delay(100);
              nosound;
            end
          else
            delay(200);
          dec(i);
        end;

      (* KЃsime vдitja nime... *)
      parimad[i].tase := mitu - 2;
      parimad[i].punkte := summa;
      TooParimadEkraanile;

      if mus then
        begin
          sound(1500 - (i + 1) * 100);
          delay(300);
          nosound;
        end;
      parimad[i].nimi := loesqna(47, 31 + i, 15);

      (* Kirjutame edetabeli „ra *)
      KirjutaParimadKettale;
      TooParimadEkraanile;
    end;
end;

Procedure LoeAvaEkraan;
var
  f: file;
begin
  assign(f,avaekraan);
  reset(f,1);
  blockread(f,abiavaekraan,sizeof(abiavaekraan));
{  blockread(f,parimad,sizeof(parimad));
  blockread(f,elekter,sizeof(elekter));}
  close(f);
end;

Function SeaEdetabel: boolean;
var
  k1, k2: Char;
  katkesta, result: boolean;
begin
  TooParimadEkraanile;
  KontrolliEdetabel;
  katkesta := false;
  repeat
    k1 := readkey;
    if keypressed then
      k2 := readkey;
    case k1 of
      ' ':
        begin
          result := true;
          katkesta := true;
        end;
      #27:
        begin
          result := false;
          katkesta := true;
        end;
    end;
  until katkesta;
  textbackground(black);
  textcolor(vrv);
  clrscr;
  SeaEdetabel := result;
end;

Procedure Seaekraan;
begin
  kaotakursor;
  textbackground(black);
  textcolor(vrv);
  clrscr;
  randomize;
  joon:=false;
  seisund:=paigal;
  jx:=40;
  jy:=1;
  write('ЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫ');
  for i:=1 to 47 do
  write('Ы                                                                              Ы');
  write('ЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫ');
  write('***Rixoft***    Tase:',mitu - 2:3,'  Elusid:',elusid:3,'   Punkte:',summa:10,'    Puudu:',puudu:10,'   ');
end;   {sea ekraan}

Procedure Seaelekter;
begin
for i:=1 to mitu do
  begin
    elekter[i].x:=random(76)+3;
    elekter[i].y:=random(45)+3;
    if random(10)<5 then
      elekter[i].dx:=-1
    else
      elekter[i].dx:=1;
    if random(10)<5 then
      begin
      elekter[i].dy:=-1;
      if elekter[i].dx=1 then
        elekter[i].e:='/'
      else
        elekter[i].e:='\';
      end
    else
      begin
      elekter[i].dy:=1;
      if elekter[i].dx=-1 then
        elekter[i].e:='/'
      else
        elekter[i].e:='\';
      end;
    elekter[i].vrv:=seavarv(trunc(random(15)+1));
  end;
  ekr[jy,jx,1]:=176;
end;  {sea elekter}

Procedure suurendaelusid;
begin
  inc(elusid);
  gotoxy(34,50);
  write(elusid:3);
  if mus then
    sound(2000);
  delay(1000);
  nosound;
  gotoxy(80,50);
end;

Procedure suurendasumma;
begin
  inc(summa);
  if summa mod 5000=0 then suurendaelusid;
  dec(puudu);
  gotoxy(47,50);
  write(summa:10);
  if mus then
    sound(200);
  delay(1);
  nosound;
  gotoxy(67,50);
  write(puudu:10);
  gotoxy(80,50);
end;

Procedure seaabi;
var m,n:integer;
begin
  abi:=ekr;
  for m:=1 to 49 do
    for n:=1 to 80 do
      case ekr[m,n,1] of
        176,219,192,217,218,191,179,196: abi[m,n,1]:=79;
        47,92: abi[m,n,1]:=120;
        end;
end;

Procedure kaota(m,n:integer);
begin
  abi[m,n,1]:=79;
  if abi[m-1,n,1]<>79 then abi[m-1,n,1]:=120;
  if abi[m-1,n+1,1]<>79 then abi[m-1,n+1,1]:=120;
  if abi[m,n+1,1]<>79 then abi[m,n+1,1]:=120;
  if abi[m+1,n+1,1]<>79 then abi[m+1,n+1,1]:=120;
  if abi[m+1,n,1]<>79 then abi[m+1,n,1]:=120;
  if abi[m+1,n-1,1]<>79 then abi[m+1,n-1,1]:=120;
  if abi[m,n-1,1]<>79 then abi[m,n-1,1]:=120;
  if abi[m-1,n-1,1]<>79 then abi[m-1,n-1,1]:=120;
end;

Procedure Loepunktid;
var m,n:integer;
begin
  for m:=2 to 48 do
    for n:=2 to 79 do
      begin
        if ekr[m,n,1] in[176,192,217,218,191,179,196] then
          begin
            ekr[m,n,2]:=vrv;
            ekr[m,n,1]:=219;
            suurendasumma;
          end;
        if abi[m,n,1]=32 then
          begin
            ekr[m,n,2]:=vrv;
            ekr[m,n,1]:=219;
            suurendasumma;
          end;
      end;
  c1:=#0;
  c2:=#0;
end;

Procedure Kontrolli;
label 1;
var ok:boolean;
    m,n:integer;
begin
  seaabi;
  joon:=false;
  alus:=219;
  seisund:=paigal;
  repeat
    ok:=true;
    for m:=2 to 48 do
      for n:=2 to 79 do
        if abi[m,n,1]=120 then
          begin
            ok:=false;
            kaota(m,n);
          end;
    if ok then goto 1;
    ok:=true;
    for m:=2 to 48 do
      for n:=79 downto 2 do
        if abi[m,n,1]=120 then
          begin
            ok:=false;
            kaota(m,n);
          end;
    if ok then goto 1;
    ok:=true;
    for m:=48 downto 2 do
      for n:=79 downto 2 do
        if abi[m,n,1]=120 then
          begin
            ok:=false;
            kaota(m,n);
          end;
    if ok then goto 1;
    ok:=true;
    for m:=48 downto 2 do
      for n:=2 to 79 do
        if abi[m,n,1]=120 then
          begin
            ok:=false;
            kaota(m,n);
          end;
  1:until ok;
    loepunktid;
    lo:=true;
    if puudu<1 then
      begin
        inc(mitu);
        arvutapuudu;
        alus:=219;
        seaekraan;
        seaelekter;
        lo:=false;
      end;
end;    {Kontrolli}

Procedure laks(a:s);
begin
  case a of
     yles:case seisund of
           yles: alus:=179;
           paremale: alus:=217;
           vasakule: alus:=192;
           end;
     alla:case seisund of
           alla: alus:=179;
           paremale: alus:=191;
           vasakule: alus:=218;
           end;
 paremale:case seisund of
           paremale: alus:=196;
           yles: alus:=218;
           alla: alus:=192;
           end;
 vasakule:case seisund of
           vasakule: alus:=196;
           yles: alus:=191;
           alla: alus:=217;
           end;
 end;
seisund:=a;
end;    {laks}

Procedure Liikumine;
var b:boolean;
begin
  b:=true;
  repeat
    if keypressed then
      begin
        c1:=readkey;
        if keypressed then
          c2:=readkey;
      end;
  until not keypressed;
  case c1 of
    #0: case c2 of
          #72: if not(joon) and (jy>1) and not (ekr[jy-1,jx,1] in[47,92]) then
                 begin
                   ekr[jy,jx,1]:=219;
                   if ekr[jy-1,jx,1]=32 then
                     begin
                     joon:=true;
                     ekr[jy-1,jx,2]:=vrv;
                     end;
                   seisund:=yles;
                   dec(jy);
                   ekr[jy,jx,1]:=176;
                 end
               else
                 if joon then
                   begin
                     case ekr[jy-1,jx,1] of
                       219:kontrolli;
                        32:laks(yles);
                       else
                           b:=false;
                       end;
                     if lo then ekr[jy,jx,1]:=alus;
                     if b and lo then dec(jy);
                     ekr[jy,jx,2]:=vrv;
                     ekr[jy,jx,1]:=176;
                   end;
          #80: if not(joon) and (jy<49) and not (ekr[jy+1,jx,1] in[47,92]) then
                 begin
                   ekr[jy,jx,1]:=219;
                   if ekr[jy+1,jx,1]=32 then
                     begin
                     joon:=true;
                     ekr[jy+1,jx,2]:=vrv;
                     end;
                   seisund:=alla;
                   inc(jy);
                   ekr[jy,jx,1]:=176;
                 end
               else
                 if joon then
                   begin
                     case ekr[jy+1,jx,1] of
                       219:kontrolli;
                        32:laks(alla);
                     else
                        b:=false;
                     end;
                     if lo then ekr[jy,jx,1]:=alus;
                     if b and lo then inc(jy);
                     ekr[jy,jx,2]:=vrv;
                     ekr[jy,jx,1]:=176;
                   end;
          #75: if not(joon) and (jx>1) and not (ekr[jy,jx-1,1] in[47,92]) then
                 begin
                   ekr[jy,jx,1]:=219;
                   if ekr[jy,jx-1,1]=32 then
                     begin
                     joon:=true;
                     ekr[jy,jx-1,2]:=vrv;
                     end;
                   seisund:=vasakule;
                   dec(jx);
                   ekr[jy,jx,1]:=176;
                 end
               else
                 if joon then
                   begin
                     case ekr[jy,jx-1,1] of
                       219:kontrolli;
                        32:laks(vasakule);
                     else
                           b:=false;
                     end;
                     if lo then ekr[jy,jx,1]:=alus;
                     if b and lo then dec(jx);
                     ekr[jy,jx,2]:=vrv;
                     ekr[jy,jx,1]:=176;
                   end;
          #77: if not(joon) and (jx<80) and not (ekr[jy,jx+1,1] in[47,92]) then
                 begin
                   ekr[jy,jx,1]:=219;
                   if ekr[jy,jx+1,1]=32 then
                     begin
                     joon:=true;
                     ekr[jy,jx+1,2]:=vrv;
                     end;
                   seisund:=paremale;
                   inc(jx);
                   ekr[jy,jx,1]:=176;
                 end
               else
                 if joon then
                   begin
                     case ekr[jy,jx+1,1] of
                       219:kontrolli;
                        32:laks(paremale);
                     else
                           b:=false;
                     end;
                     if lo then ekr[jy,jx,1]:=alus;
                     if b and lo then inc(jx);
                     ekr[jy,jx,2]:=vrv;
                     ekr[jy,jx,1]:=176;
                   end;
          end;
    '-':begin
         c1:=#0;
         inc(samm,3);
        end;
    '+':begin
          if samm >= 3 then
            dec(samm,3);
          c1:=#0;
        end;
    'm','M':
        begin
          mus := not mus;
          c1:=#0;
        end;
    end;  {case c1}
  lo:=true;
end;        {liikumine}

Procedure vahendaelusid;
begin
  dec(elusid);
  gotoxy(34,50);
  write(elusid:3);
  if mus then
    sound(2000);
  delay(100);
  nosound;
  gotoxy(80,50);
end;

Procedure SOS;
var m,n:integer;
begin
  vahendaelusid;
  for m:=2 to 48 do
    for n:=2 to 79 do
      if ekr[m,n,1] in[176,192,217,218,191,179,196] then
          begin
            ekr[m,n,2]:=0;
            ekr[m,n,1]:=32;
            inc(summa);
          end;
  jx:=40;
  jy:=1;
  c1:=#0;
  c2:=#0;
  ekr[jy,jx,1]:=176;
  joon:=false;
end;

Procedure Arvutaelekter;
var ddx,ddy:shortint;
begin
  for i:=1 to mitu do
    begin
      ddx:=elekter[i].dx;
      ddy:=elekter[i].dy;
      ekr[elekter[i].y,elekter[i].x,1]:=32;
      if (ekr[elekter[i].y,elekter[i].x+elekter[i].dx,1] in[219]) or
          ((ekr[elekter[i].y,elekter[i].x+elekter[i].dx,1] in[176]) and not joon)
       then
        begin
        ddx:=elekter[i].dx*(-1);
        elekter[i].dx:=0;
        if elekter[i].e='\' then
          elekter[i].e:='/'
        else
          elekter[i].e:='\';
        end;
      if (ekr[elekter[i].y+elekter[i].dy,elekter[i].x+elekter[i].dx,1] in[219]) or
         ((ekr[elekter[i].y+elekter[i].dy,elekter[i].x+elekter[i].dx,1] in[176]) and not joon)
       then
        begin
        ddy:=elekter[i].dy*(-1);
        elekter[i].dy:=0;
        if elekter[i].e='\' then
          elekter[i].e:='/'
        else
          elekter[i].e:='\';
        end;
      elekter[i].x:=elekter[i].x+elekter[i].dx;
      elekter[i].y:=elekter[i].y+elekter[i].dy;
      elekter[i].dx:=ddx;
      elekter[i].dy:=ddy;
      if (ekr[elekter[i].y,elekter[i].x,1] in[176,192,217,218,191,179,196])
               and joon then
        sos;
      if elekter[i].e='/' then
        begin
        ekr[elekter[i].y,elekter[i].x,2]:=elekter[i].vrv;
        ekr[elekter[i].y,elekter[i].x,1]:=ord('/')
        end
      else
        begin
        ekr[elekter[i].y,elekter[i].x,2]:=elekter[i].vrv;
        ekr[elekter[i].y,elekter[i].x,1]:=ord('\');
        end;
    end;
end;   {arvuta elekter}

var
  OrigMode: Integer;

begin   {p“hiprogramm}
  LoeAvaEkraan;
  LoeParimadKettalt;
  OrigMode := LastMode;
  textmode(c80+font8X8);
  samm:=90;   {kiirus, mida saab + ja - muuta}
  mus:=true;  {muusika muutuja}
  summa:=0;   {alg punktisumma}
  mitu := -1;
  while seaedetabel do
    begin
      lo:=True;   {lдpeta punktide lugemine}
      mitu:=3;    {mitu kolli on alguses}
      c1:=#0;
      c2:=#0;
      summa:=0;   {alg punktisumma}
      elusid:=5; {elusid alguses}
      alus:=219;  {jooksiku alla j„„v ruut}
      arvutapuudu;
      seaekraan;
      seaelekter;
      repeat
        arvutaelekter;
        liikumine;
        delay(samm);
      until (c1=#27) or (elusid<1);
    end;
  textmode(origmode);
end.