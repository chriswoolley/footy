unit Dream1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, OleCtrls, SHDocVw, MSHTML, Player, Excel, dxDBCtrl, dxDBGrid,
  dxTL, Db, ExtCtrls, dxCntner, dxmdaset;

type
  TFrmDreamTeamScore = class(TForm)
    webBrowse: TWebBrowser;
    mmoHTML: TMemo;
    mmoStages: TMemo;
    dxmData: TdxMemData;
    dsData: TDataSource;
    grdData: TdxDBGrid;
    Panel1: TPanel;
    btnUpdate: TButton;
    btnToExcel: TButton;
    btnEdit: TButton;
    edtDAT: TEdit;
    edtXLS: TEdit;
    dxmDataID: TIntegerField;
    dxmDataName: TStringField;
    dxmDataCountry: TStringField;
    dxmDataCost: TFloatField;
    dxmDataPoints1: TIntegerField;
    dxmDataPoints2: TIntegerField;
    dxmDataPoints3: TIntegerField;
    btnWeb: TButton;
    btnSave: TButton;
    grdDataRecId: TdxDBGridColumn;
    grdDataID: TdxDBGridMaskColumn;
    grdDataName: TdxDBGridMaskColumn;
    grdDataCountry: TdxDBGridMaskColumn;
    grdDataCost: TdxDBGridMaskColumn;
    grdDataPoints1: TdxDBGridMaskColumn;
    grdDataPoints2: TdxDBGridMaskColumn;
    grdDataPoints3: TdxDBGridMaskColumn;
    procedure btnUpdateClick(Sender: TObject);
    procedure webBrowseNavigateComplete2(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure webBrowseDocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnToExcelClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnWebClick(Sender: TObject);
    procedure grdDataEdited(Sender: TObject; Node: TdxTreeListNode);
    procedure btnSaveClick(Sender: TObject);
  private
    { Private declarations }
    FPlayers : TPlayers;
    FPage  : IDispatch;
    FStage : Integer;
    procedure Display;
    procedure Save;
    procedure Load;
    procedure Edit;
    procedure Parse;
    procedure Process;
  public
    { Public declarations }

  end;

var
  FrmDreamTeamScore: TFrmDreamTeamScore;

implementation

{$R *.DFM}

procedure TFrmDreamTeamScore.Parse;
const
  Match = 'PlayerProfile?playerid=';

var
  New : Boolean;
  Str  : String;
  Idx,
  P,
  Line : Integer;
  Play : TPlayer;
begin
(*
<TD width=40><SPAN class=black12>001</SPAN></TD>
<TD width=190><A class=redtoblack12 href="PlayerProfile?playerid=2709&amp;gameid=78">German Burgos</A></TD>
<TD align=middle width=120><SPAN class=black12>Argentina </SPAN></TD>
<TD align=middle width=60><SPAN class=black12>£5.0m </SPAN></TD>
<TD align=middle width=50><SPAN class=black12>0 </SPAN></TD></TR>
<TR bgColor=#ffe19a>
*)
  Line := 0;
  while Line<mmoHTML.Lines.Count do begin
    Str := mmoHTML.Lines[Line];
    P := Pos(Match,Str);
    if P<>0 then begin
      Play := TPlayer.Create;

      Str := mmoHTML.Lines[Line-1];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      Play.ID := StrToInt(Str);

      Idx := FPlayers.IndexOf(Play.ID);
      New := Idx=-1;
      if not New then begin
        Play.Free;
        Play := FPlayers[Idx];
      end;

      Str := mmoHTML.Lines[Line];
      P := Pos(Match,Str);
      Delete(Str,1,P+Length(Match)-1);
      P := Pos('&',Str);
      Play.Profile := StrToInt(Copy(Str,1,P-1));

      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      Play.Name := Str;
      Inc(Line);

      Str := mmoHTML.Lines[Line];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      Play.Country := Str;
      Inc(Line);

      Str := mmoHTML.Lines[Line];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      Play.Price := StrToFloat(Copy(Str,2,Length(Str)-2));
      Inc(Line);

      Str := mmoHTML.Lines[Line];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      if New then
        Play.Points1 := StrToInt(Str)
      else
        Play.Points2 := StrToInt(Str) - Play.Points1;
      Play.Points3 := StrToInt(Str);
      Inc(Line);

      if New then
        FPlayers.Add(Play);
      Play := Nil; if Play=Nil then ;
    end else
      Inc(Line);
  end;    { while }
end;

procedure TFrmDreamTeamScore.Process;
begin
  if mmoStages.Lines.Count>FStage then
    webBrowse.Navigate(mmoStages.Lines[FStage])
  else
    Screen.Cursor := crDefault;
end;

procedure TFrmDreamTeamScore.btnUpdateClick(Sender: TObject);
begin
  FPlayers.Filename := edtDAT.Text;
  if FileExists(FPlayers.Filename) then
    Load;

//  WebBrowser1.Navigate('http://www.dreamteamfc.com/Sun/servlet/PostPlayerList?catidx=3');
//  WebBrowser1.Navigate('http://www.google.co.uk');
  Screen.Cursor := crHourGlass;
  FStage := 0;
  Process;
  FPlayers.Sort;
  FPlayers.Save;
  mmoHTML.BringToFront;
  Display;
end;

procedure TFrmDreamTeamScore.webBrowseNavigateComplete2(Sender: TObject; const pDisp: IDispatch; var URL: OleVariant);
begin
  if FPage = nil then
    FPage := pDisp; { save for comparison }
end;

procedure TFrmDreamTeamScore.webBrowseDocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
var
  I : IHTMLDocument2;
begin
  if (pDisp = FPage) then begin
    {the document is loaded, not just a frame }
    I := webBrowse.Document as IHTMLDocument2;
    mmoHTML.Text := I.Body.innerHTML;
    try
      Parse;
    except
    end;
    mmoHTML.Lines.SaveToFile(Format('%03d.txt',[FStage]));
    Inc(FStage);
    Process;
    FPage := nil; {clear the global variable }
  end;
end;

procedure TFrmDreamTeamScore.FormCreate(Sender: TObject);
begin
  FPlayers := TPlayers.Create;
  FPlayers.Filename := edtDAT.Text;
end;

procedure TFrmDreamTeamScore.FormDestroy(Sender: TObject);
begin
  FPlayers.Free;
end;

procedure TFrmDreamTeamScore.Save;
begin
  FPlayers.Save;
end;

procedure TFrmDreamTeamScore.Load;
begin
  FPlayers.Clear;
  FPlayers.Load;
end;

procedure TFrmDreamTeamScore.Edit;
var
  C : Integer;
begin
  FPlayers.Clear;
  FPlayers.Load;

  dxmData.Open;
  while not dxmData.Eof do begin
    dxmData.Delete;
  end;    { while }
  for C := 0 to FPlayers.Count-1 do { Iterate } begin
    dxmData.Append;
    dxmData.FieldByName('ID').AsInteger := FPlayers[C].ID;
    dxmData.FieldByName('NAME').AsString := FPlayers[C].Name;
    dxmData.FieldByName('COUNTRY').AsString := FPlayers[C].Country;
    dxmData.FieldByName('COST').AsFloat := FPlayers[C].Price;
    dxmData.FieldByName('POINTS1').AsInteger := FPlayers[C].Points1;
    dxmData.FieldByName('POINTS2').AsInteger := FPlayers[C].Points2;
    dxmData.FieldByName('POINTS3').AsInteger := FPlayers[C].Points3;
    dxmData.Post;
  end;    { for }
  grdData.BringToFront;
end;

procedure TFrmDreamTeamScore.Display;
var
  C : Integer;
begin
  mmoHTML.Clear;
  for C := 0 to FPlayers.Count-1 do { Iterate } begin
    mmoHTML.Lines.Add(IntToStr(FPlayers[C].ID)+' '+FPlayers[C].Name+' '+FPlayers[C].Country+' '+FloatToStr(FPlayers[C].Price)+' '+IntToStr(FPlayers[C].Points1)+' '+IntToStr(FPlayers[C].Points2)+' '+IntToStr(FPlayers[C].Points3));
  end;    { for }
end;

const
  colID = 27; {AA}
  colName = 28;
  colCountry = 29;
  colPrice = 30;
  colPoints1 = 31;
  colPoints2 = 32;
  colPoints3 = 33;

procedure TFrmDreamTeamScore.btnToExcelClick(Sender: TObject);
var
  C : Integer;
  Excel : TExcel;
begin
  {}
  Excel := TExcel.Create;
  try
    try
      Screen.Cursor := crHourGlass;
      Excel.Open(edtXLS.Text,foExcel);

      for C := 0 to FPlayers.Count-1 do { Iterate } begin
        Excel.Cell[colID,C+2] := FPlayers[C].ID;
        Excel.Cell[colName,C+2] := FPlayers[C].Name;
        Excel.Cell[colCountry,C+2] := FPlayers[C].Country;
        Excel.Cell[colPrice,C+2] := FPlayers[C].Price;
        Excel.Cell[colPoints1,C+2] := FPlayers[C].Points1;
        Excel.Cell[colPoints2,C+2] := FPlayers[C].Points2;
        Excel.Cell[colPoints3,C+2] := FPlayers[C].Points3;
      end;    { for }

      Excel.Close(edtXLS.Text,True);
      Excel.Free;
    finally
      Screen.Cursor := crDefault;
    end;
  except
    Excel.Quit;
    raise;
  end;
end;

procedure TFrmDreamTeamScore.btnEditClick(Sender: TObject);
begin
  Edit;
end;

procedure TFrmDreamTeamScore.btnWebClick(Sender: TObject);
const
  C : Integer = 0;
begin
  Inc(C);
  if C>3 then
    C := 1;
  case C of
    1 : webBrowse.BringToFront;
    2 : mmoHTML.BringToFront;
    3 : grdData.BringToFront;
  end;
end;

procedure TFrmDreamTeamScore.grdDataEdited(Sender: TObject; Node: TdxTreeListNode);
var
  Idx : Integer;
  Play : TPlayer;
begin
//  Node;
  Idx := FPlayers.IndexOf(Node.Values[1]);
//  Idx := FPlayers.IndexOf(Node.Values[0]);
  Play := FPlayers[Idx];
  Play.Points1 := Node.Values[5];
  Play.Points2 := Node.Values[6];
  Play.Points3 := Node.Values[7];
end;

procedure TFrmDreamTeamScore.btnSaveClick(Sender: TObject);
begin
  FPlayers.Save;
end;

end.

