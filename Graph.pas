unit Graph;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, TeeProcs, TeEngine, Chart, Series, StdCtrls, Db, DBTables, Constants,
  CheckLst, ComCtrls, Database ,Ora, OraSmart, MemDS, OraError;

type
  Troolean = (No,Yes,Was);

type
  TFrmGraph = class(TForm)
    pagPages: TPageControl;
    tabSelection: TTabSheet;
    tabTeam: TTabSheet;
    dtmFrom: TDateTimePicker;
    dtmTo: TDateTimePicker;
    cklTeam: TCheckListBox;
    chkChange: TCheckBox;
    chtTeam: TChart;
    lblFrom: TLabel;
    lblTo: TLabel;
    lblTeams: TLabel;
    chkFrom: TCheckBox;
    chkTo: TCheckBox;
    lblPlayers: TLabel;
    cklPlayer: TCheckListBox;
    tabPlayer: TTabSheet;
    chtPlayer: TChart;
    edtCSV: TEdit;
    procedure Button3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pagPagesChange(Sender: TObject);
    procedure cklTeamDblClick(Sender: TObject);
    procedure dtmFromChange(Sender: TObject);
    procedure chkFromClick(Sender: TObject);
    procedure dtmToChange(Sender: TObject);
    procedure chkToClick(Sender: TObject);
    procedure chkChangeClick(Sender: TObject);
    procedure cklTeamClick(Sender: TObject);
    procedure cklTeamClickCheck(Sender: TObject);
    procedure cklTeamMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FDoPlayers : Boolean;
    FDoLivePlayers : Boolean;
    FPlayers : Array[0..128] of Array[0..1024] of Troolean;
    FAborted : Boolean;
    FChanged : Boolean;
    procedure GraphTeam;
    procedure GraphPlayer;
    procedure DoOnClick(Sender:TChartSeries; ValueIndex: LongInt; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DoOnClickLegend(Sender: TCustomChart; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    { Public declarations }
  end;

var
  FrmGraph: TFrmGraph;

implementation

{$R *.DFM}

type
  TInteger = class(TObject)
    Value : Integer;
    constructor Create(AValue : Integer);
  end;

  constructor TInteger.Create(AValue : Integer);
  begin
    Value := AValue;
  end;

procedure TFrmGraph.DoOnClick(Sender:TChartSeries; ValueIndex: LongInt; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Serie : TLineSeries;
begin
  Serie := Sender as TLineSeries;
  case pagPages.ActivePage.TabIndex of    { }
    0 : ;
    1 : chtTeam.Title.Text.Text := Serie.Title;
    2 : chtPlayer.Title.Text.Text := Serie.Title;
    3 : ;
  end;    { case }
  Serie.Marks.Visible := not Serie.Marks.Visible;
end;

procedure TFrmGraph.DoOnClickLegend(Sender: TCustomChart; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  zWidth : Integer = 2;
var
  C : Integer;
  Serie : TLineSeries;
  Chart : TChart;
begin
  Chart := Sender as TChart;
  Inc(zWidth);
  if zWidth>10 then
   zWidth := 1; 
  for C := 0 to Chart.SeriesList.Count-1 do { Iterate } begin
    Serie := Chart.SeriesList[C] as TLineSeries;
    Serie.LinePen.Width := zWidth;
  end;    { for }
end;

procedure TFrmGraph.GraphTeam;
var
  DoF : Boolean;
  F : TextFile;
  Used : Array[37400..66000] of Boolean;
  D,
  C : Integer;
  Series : TChartSeries;
  Min,
  Date   : TDateTime;
  Sum    : Integer;
  Qry    : TOraQuery;
  Team : String;
  LSelectedCount : integer;

  procedure NewSeries;
  const
    Style : TSeriesPointerStyle = psRectangle;
  begin
    Series := TLineSeries.Create(chtTeam);
    Series.OnClick := DoOnClick;
    Series.Title := Qry.FieldByName('NAME').AsString;//+':'+Qry.FieldByName('TEAM').AsString;
    Series.ParentChart := chtTeam;
    Series.Tag := Qry.FieldByName('personid').AsInteger;
    Series.Marks.Style := smsValue;
    (Series as TLineSeries).Pointer.Visible := True;
    (Series as TLineSeries).LinePen.Width := 2;
    (Series as TLineSeries).Pointer.Style := Style;
    Style := Succ(Style);
    if Style=psSmalLDot then
      Style := psRectangle;
    if chkFrom.Checked then
      Series.AddXY(dtmFrom.Date,0,DateToStr(dtmFrom.Date))
    else
      Series.AddXY(Min,0,DateToStr(Min));
  end;
begin
  DoF := False;
  if edtCSV.Text<>'' then begin
    AssignFile(F,edtCSV.Text);
    try
      ReWrite(F);
      Writeln(F,'"Team","Date","Points"');
      DoF := True;
    except
    end;
  end;

  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin


////    Add('SELECT   SUM (p.POINTS) AS x,  o.personid, o.NAME, p.fromat');
////    Add(', p.untilat');
////    Add('    FROM person o, points p, squad s');
////    Add('   WHERE o.personid IN (');
//    for C := 0 to cklTeam.Items.Count-1 do    { Iterate } begin
//      if cklTeam.Checked[C] then begin
//        Add(IntToStr(TInteger(cklTeam.Items.Objects[C]).Value));
//        Add(',');
//      end;
//    end;    { for }
//    if cklTeam.Items.Count > 0 then
//      Delete(SQL.Count-1);
////    Add('   ) AND  s.PERSONID = o.personid');
////    Add('   AND  p.playerid = s.PLAYERID');
////    Add('   AND (s.fromat < p.fromat) AND (s.untilat >= p.untilat)');
////    Add('GROUP BY o.personid, o.NAME, p.fromat, p.untilat');
////    Add('ORDER BY p.fromat');
    Clear;
    Add('select');
    Add('SUM (o.POINTS) AS x,  PS.personid, PS.NAME, p.fromat');
//    Add('s.personid, sum(o.points) as points');
    Add('from');
    Add('playing p, points o, squad s, person ps');
//    Add('where');
    LSelectedCount := 0;
    for C := 0 to cklTeam.Items.Count-1 do    { Iterate }
    begin
      if cklTeam.Checked[C] then
        inc(LSelectedCount);
    end;

    if LSelectedCount <> 0 then
    begin
      Add('   WHERE PS.PERSONID IN (');
      for C := 0 to cklTeam.Items.Count-1 do    { Iterate } begin
        if cklTeam.Checked[C] then begin
          Add(IntToStr(TInteger(cklTeam.Items.Objects[C]).Value));
          Add(',');
        end;
      end;    { for }
      if cklTeam.Items.Count > 0 then
        Delete(SQL.Count-1);
      Add(') and ');
    end
    else
      Add(' WHERE ');
    Add('s.squadid=p.squadid and');
    Add('p.playerid=o.playerid and');
    Add('o.fromat+0.99998843 between p.fromat and nvl(p.untilat, to_date(''01-JAN-9999''))');
//    Add('group by s.personid');
    Add('GROUP BY PS.personid, PS.NAME, p.fromat, p.untilat');
    Add('ORDER BY p.fromat');

//    Add('SELECT');
//    Add('SUM(p.DELTA) as x, t.TEAMID, t.TEAM, o.NAME, p.FROMAT, p.UNTILAT');
//    Add('FROM');
//    Add('PERSON o,');
//    Add('POINTS p,');
//    Add('TEAM t,');
//    Add('SQUAD s');
//    Add('WHERE');
//    Add('t.PERSONID=o.personid AND');
//    Add('t.TEAMID=s.teamid AND');
//    Add('s.PLAYERID=p.playerid AND');
//    Add('((s.fromat<p.fromat) and (s.untilat>=p.untilat)) and t.teamid in (');
//    Add('t.teamid in (');
////    for C := 0 to cklTeam.Items.Count-1 do    { Iterate } begin
////      if cklTeam.Checked[C] then begin
////        Add(IntToStr(TInteger(cklTeam.Items.Objects[C]).Value));
////        Add(',');
////      end;
////    end;    { for }
////    Delete(SQL.Count-1);
////    Add(')');
////    if chkFrom.Checked then
////      Add('AND P.FROMAT>:DFROM');
////    if chkTo.Checked then
////      Add('AND P.FROMAT<:DINTO');
////    Add('group by t.teamid, t.TEAM, o.NAME, p.fromat, p.untilat');
////    Add('order by t.teamid, p.fromat');
////
////    if chkFrom.Checked then
////      ParamByName('DFROM').AsDateTime := dtmFrom.Date;
////    if chkTo.Checked then
////      ParamByName('DINTO').AsDateTime := dtmTo.Date;
  end;    { with }
  Qry.Open;

  FillChar(Used,SizeOf(Used),0); {False}
  if chkFrom.Checked then
    Min := dtmFrom.Date
  else
    Min := MaxLongInt;
  while not Qry.Eof do begin
    if Qry.FieldByName('FROMAT').AsDateTime<Min then
      Min := Qry.FieldByName('FROMAT').AsDateTime;
    Used[Trunc(Qry.FieldByName('FROMAT').AsDateTime)] := True;
    Qry.Next;
  end;    { while }
  Qry.Close;
  Qry.Open;

  Series := Nil;
  chtTeam.RemoveAllSeries;
  Date := 0;
  Sum := 0;
  Team := '';
  FAborted := False;
  while (not Qry.Eof) and (not FAborted) do begin
    if (Series=Nil) or (Series.Tag<>Qry.FieldByName('personid').AsInteger) then begin
      if Series<>Nil{Sum<>0} then begin
        Series.AddXY(Date,Sum,DateToStr(Date)); {Add last point of previous graph!}
        if DoF then
          Writeln(F,'"'+Team+'","'+DateTimeToStr(Date)+'","'+IntToStr(Sum)+'"');
      end;
      NewSeries;
      Team := Qry.FieldByName('NAME').AsString;
      Sum := Qry.Fields[0].AsInteger;
      Date := Qry.FieldByName('FROMAT').AsDateTime;
     {Add points to fill in start as needed}
      for D := Trunc(Min) to Trunc(Date-1) do { Iterate } begin
        if Used[Trunc(D)] then begin
          Series.AddXY(D,0,DateToStr(D));
          if DoF then
            Writeln(F,'"'+Team+'","'+DateTimeToStr(D)+'","'+IntToStr(0)+'"');
        end;
      end;    { for }
      Application.ProcessMessages;
    end else begin
      if Trunc(Date)<>Trunc(Qry.FieldByName('FROMAT').AsDateTime) then begin
        Sum := Sum + Qry.Fields[0].AsInteger;
        Series.AddXY(Date,Sum,DateToStr(Date));
        if DoF then
          Writeln(F,'"'+Team+'","'+DateTimeToStr(Date)+'","'+IntToStr(Sum)+'"');
        if chkChange.Checked then
          Sum := Qry.Fields[0].AsInteger;
        Date := Qry.FieldByName('FROMAT').AsDateTime;
      end;
    end;
    Qry.Next;
  end;    { while }
  Series.AddXY(Date,Sum,DateToStr(Date));

  if DoF then
    Writeln(F,'"'+Team+'","'+DateTimeToStr(Date)+'","'+IntToStr(Sum)+'"');

  Qry.Close;
  Qry.Free;

  if DoF then begin
    CloseFile(F);
  end;
end;


procedure TFrmGraph.GraphPlayer;
var
  DoF : Boolean;
  F : TextFile;
  Used : Array[37400..66000] of Boolean;
  D,
  C : Integer;
  Series : TChartSeries;
  Min,
  Date   : TDateTime;
  Total,
  Sum    : Integer;
  Qry    : TOraQuery;
  Player : String;
  procedure NewSeries;
  const
    Style : TSeriesPointerStyle = psRectangle;
  begin
    Series := TLineSeries.Create(chtPlayer);
    Series.OnClick := DoOnClick;
    Series.Title := Qry.FieldByName('NAME').AsString;//+':'+Qry.FieldByName('PLAYERTEAM').AsString;
    Series.ParentChart := chtPlayer;
    Series.Tag := Qry.FieldByName('PLAYERID').AsInteger;
    Series.Marks.Style := smsValue;
    (Series as TLineSeries).Pointer.Visible := True;
    (Series as TLineSeries).LinePen.Width := 2;
    (Series as TLineSeries).Pointer.Style := Style;
    Style := Succ(Style);
    if Style=psSmalLDot then
      Style := psRectangle;
    if chkFrom.Checked then
      Series.AddXY(dtmFrom.Date,0,DateToStr(dtmFrom.Date))
    else
      Series.AddXY(Min,0,DateToStr(Min));
  end;
begin
  DoF := False;
  if edtCSV.Text<>'' then begin
    AssignFile(F,edtCSV.Text);
    try
      ReWrite(F);
      Writeln(F,'"Player","Date","Points"');
      DoF := True;
    except
    end;
  end;

  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('SELECT');
//    Add('sum(p.delta) as x, r.playerteam, r.NAME, p.fromat, p.playerid, p.untilat');
    Add('sum(p.POINTS) as x, r.NAME, p.fromat, p.playerid, p.untilat');
    Add('FROM');
    Add('player r,');
    Add('points p');
    Add('WHERE');
    Add('r.playerid=p.playerid AND');
    Add('r.playerid in (');
    Total := 0;
    for C := 0 to cklPlayer.Items.Count-1 do    { Iterate } begin
      if cklPlayer.Checked[C] then begin
//        Add(IntToStr((cklPlayer.Items.Objects[C] as TInteger).Value));
        Add(IntToStr(TInteger(cklPlayer.Items.Objects[C]).Value));
        Add(',');
        Inc(Total);
      end;
    end;    { for }
    Delete(SQL.Count-1);
    Add(')');
    if Total=0 then
      exit;
    if chkFrom.Checked then
      Add('AND P.FROMAT>:DFROM');
    if chkTo.Checked then
      Add('AND P.FROMAT<:DINTO');
//    Add('group by p.playerid, r.playerteam, r.NAME, p.fromat, p.untilat');
    Add('group by p.playerid, r.NAME, p.fromat, p.untilat');
    Add('order by p.playerid, p.fromat');

    if chkFrom.Checked then
      ParamByName('DFROM').AsDateTime := dtmFrom.Date;
    if chkTo.Checked then
      ParamByName('DINTO').AsDateTime := dtmTo.Date;
  end;    { with }
  Qry.Open;

  FillChar(Used,SizeOf(Used),0); {False}
//  Min := MaxLongInt;
  if chkFrom.Checked then
    Min := dtmFrom.Date
  else
    Min := MaxLongInt;
  while not Qry.Eof do begin
    if Qry.FieldByName('FROMAT').AsDateTime<Min then
      Min := Qry.FieldByName('FROMAT').AsDateTime;
    D := Trunc(Qry.FieldByName('FROMAT').AsDateTime);
    try
      Used[D] := True;
    except
      ShowMessage(Qry.FieldByName('FROMAT').AsString);
    end;
    Qry.Next;
  end;    { while }
  Qry.Close;
  Qry.Open;

  Series := Nil;
  chtPlayer.RemoveAllSeries;
  Date := 0;
  Sum := 0;
  Player := '';
  FAborted := False;
  while (not Qry.Eof) and (not FAborted) do begin
    if (Series=Nil) or (Series.Tag<>Qry.FieldByName('PLAYERID').AsInteger) then begin
      if Series<>Nil{Sum<>0} then begin
        Series.AddXY(Date,Sum,DateToStr(Date)); {Add last point of previous graph!}
        if DoF then
          Writeln(F,'"'+Player+'","'+DateTimeToStr(Date)+'","'+IntToStr(Sum)+'"');
      end;
      NewSeries;
      Player := Qry.FieldByName('NAME').AsString;
      Sum := Qry.Fields[0].AsInteger;
      Date := Qry.FieldByName('FROMAT').AsDateTime;
     {Add points to fill in start as needed}
      for D := Trunc(Min) to Trunc(Date-1) do { Iterate } begin
        if Used[Trunc(D)] then begin
          Series.AddXY(D,0,DateToStr(D));
          if DoF then
            Writeln(F,'"'+Player+'","'+DateTimeToStr(D)+'","'+IntToStr(0)+'"');
        end;
      end;    { for }
      Application.ProcessMessages;
    end else begin
      Sum := Sum + Qry.Fields[0].AsInteger;
      if Trunc(Date)<>Trunc(Qry.FieldByName('FROMAT').AsDateTime) then begin
        Series.AddXY(Date,Sum,DateToStr(Date));
        if DoF then
          Writeln(F,'"'+Player+'","'+DateTimeToStr(Date)+'","'+IntToStr(Sum)+'"');
        if chkChange.Checked then
          Sum := Qry.Fields[0].AsInteger;
        Date := Qry.FieldByName('FROMAT').AsDateTime;
      end;
    end;
    Qry.Next;
  end;    { while }
  Series.AddXY(Date,Sum,DateToStr(Date));

  if DoF then
    Writeln(F,'"'+Player+'","'+DateTimeToStr(Date)+'","'+IntToStr(Sum)+'"');

  Qry.Close;
  Qry.Free;

  if DoF then begin
    CloseFile(F);
  end;
end;

procedure TFrmGraph.Button3Click(Sender: TObject);
begin
  FAborted := True;
end;

procedure TFrmGraph.FormShow(Sender: TObject);
var
  Qry : TOraQuery;
begin
  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('SELECT * FROM PERSON O');
    Open;
    while not Eof do begin
      cklTeam.Items.AddObject(Qry.FieldByName('NAME').AsString+':'+Qry.FieldByName('TEAM').AsString,TInteger.Create(Qry.FieldByName('PERSONID').AsInteger));
//      cklTeam.Checked[cklTeam.Items.Count-1] := Qry.FieldByName('VALID').AsBoolean;
      Next;
    end; { while }
    Close;
  end;
  Qry.Free;

  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('SELECT P.*, T.NAME AS PLAYERTEAM FROM PLAYER P, TEAM T');
    Add('WHERE T.TEAMID=P.TEAMID');
    Open;
    while not Eof do begin
      cklPlayer.Items.AddObject(Qry.FieldByName('NAME').AsString+':'+Qry.FieldByName('PLAYERTEAM').AsString,TInteger.Create(Qry.FieldByName('PLAYERID').AsInteger));
      Next;
    end; { while }
    Close;
  end;
  Qry.Free;

  FillChar(FPlayers,SizeOf(FPlayers),0); {False}
  Qry := TOraQuery.Create(Nil);

  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('SELECT P.TEAMID, P.PLAYERID, S.UNTILAT FROM PLAYER P, SQUAD S WHERE P.PLAYERID=S.PLAYERID');
    Open;
    while not Eof do begin
      if FieldByName('UNTILAT').AsDateTime>Date then
        FPlayers[Qry.FieldByName('TEAMID').AsInteger,Qry.FieldByName('PLAYERID').AsInteger] := Yes
      else
        FPlayers[Qry.FieldByName('TEAMID').AsInteger,Qry.FieldByName('PLAYERID').AsInteger] := Was;
      Next;
    end; { while }
    Close;
  end;
  Qry.Free;

  chtTeam.OnClickLegend := DoOnClickLegend;
  chtPlayer.OnClickLegend := DoOnClickLegend;
  FChanged := True;
end;

procedure TFrmGraph.pagPagesChange(Sender: TObject);
begin
  if (pagPages.ActivePage=tabTeam) and (FChanged) then begin
    GraphTeam;
    FChanged := False;
  end;
  if (pagPages.ActivePage=tabPlayer) and (FChanged) then begin
    GraphPlayer;
    FChanged := False;
  end;
end;

procedure TFrmGraph.cklTeamDblClick(Sender: TObject);
const
  Check : Boolean = False;
var
  C : Integer;
  Lst : TCheckListBox;
begin
  Lst := Sender as TCheckListBox;
  for C := 0 to Lst.Items.Count-1 do { Iterate } begin
    Lst.Checked[C] := Check;
  end;    { for }
  Check := not Check;
  FDoPlayers := False;
  FDoLivePlayers := False;
//  cklTeamClickCheck(Sender);
  FChanged := True;
end;

procedure TFrmGraph.dtmFromChange(Sender: TObject);
begin
  FChanged := True;
end;

procedure TFrmGraph.chkFromClick(Sender: TObject);
begin
  FChanged := True;
end;

procedure TFrmGraph.dtmToChange(Sender: TObject);
begin
  FChanged := True;
end;

procedure TFrmGraph.chkToClick(Sender: TObject);
begin
  FChanged := True;
end;

procedure TFrmGraph.chkChangeClick(Sender: TObject);
begin
  FChanged := True;
end;

procedure TFrmGraph.cklTeamClick(Sender: TObject);
begin
  FChanged := True;
end;

procedure TFrmGraph.cklTeamClickCheck(Sender: TObject);
var
  C : Integer;
  D : Integer;
  T : Integer;
  P : Integer;
begin
  FChanged := True;
  for C := 0 to cklPlayer.Items.Count-1 do    { Iterate } begin
    cklPlayer.Checked[C] := False;
  end;    { for }
(*
  D := 0;
  for C := 0 to cklTeam.Items.Count-1 do { Iterate } begin
    if cklTeam.Checked[C] then
      Inc(D);
  end;
*)
  if (FDoPlayers) or (FDoLivePlayers) then
    for C := 0 to cklTeam.Items.Count-1 do { Iterate } begin
      if cklTeam.Checked[C] then begin
        T := (cklTeam.Items.Objects[C] as TInteger).Value;
        for D := 0 to cklPlayer.Items.Count-1 do begin
          P := (cklPlayer.Items.Objects[D] as TInteger).Value;
          cklPlayer.Checked[D] := cklPlayer.Checked[D] or ((FPlayers[T,P]=Yes) and FDoPlayers);
          cklPlayer.Checked[D] := cklPlayer.Checked[D] or ((FPlayers[T,P]=Was) and FDoLivePlayers);
        end;
      end;
    end;    { for }
end;

procedure TFrmGraph.cklTeamMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ssCtrl in Shift then
    FDoPlayers := True
  else
    FDoPlayers := False;
  if ssShift in Shift then
    FDoLivePlayers := True
  else
    FDoLivePlayers := False;
end;

procedure TFrmGraph.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
