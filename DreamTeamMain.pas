unit DreamTeamMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, OleCtrls, SHDocVw, MSHTML, Player, Excel, dxDBCtrl, dxDBGrid, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Math,
  dxTL, Db, ExtCtrls, dxCntner, dxmdaset, Utilities, Login, Person, Point, Previous, DreamTeam,
  Team, EMailServer, SyncObjs, Contnrs, AppEvnts, IdPOP3, IdMessage,
  Database, constants,Squad, papertalks;

type
  TProcess = procedure of object;

type
  TFrmDreamTeamScore = class;

  TMyThread = class(TThread)
  private
    FEvent : TEvent;
    FForm : TFrmDreamTeamScore;
  protected
    procedure Serve;
  public
    constructor Create(ASuspended : Boolean);
    destructor Destroy; override;
    procedure Execute; override;
    property Event : TEvent read FEvent;
    property Form : TFrmDreamTeamScore write FForm;
  published
  end;

  TFrmDreamTeamScore = class(TForm)
    webBrowse: TWebBrowser;
    mmoHTML: TMemo;
    Panel1: TPanel;
    btnUpdate: TButton;
    btnWeb: TButton;
    btnDetails: TButton;
    btnRetry: TButton;
    btnReParse: TButton;
    btnPack: TButton;
    btnEMail: TButton;
    btnCheck: TButton;
    mmoStages: TMemo;
    dlgOpen: TOpenDialog;
    btnAuction: TButton;
    btnRumor: TButton;
    btnPlayers: TButton;
    btnStop: TButton;
    btnServe: TButton;
    Label1: TLabel;
    procedure btnUpdateClick(Sender: TObject);
    procedure webBrowseNavigateComplete2(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure webBrowseDocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnToExcelClick(Sender: TObject);
    procedure btnWebClick(Sender: TObject);
    procedure grdDataEdited(Sender: TObject; Node: TdxTreeListNode);
    procedure btnDetailsClick(Sender: TObject);
    procedure btnRetryClick(Sender: TObject);
    procedure btnReParseClick(Sender: TObject);
    procedure btnPackClick(Sender: TObject);
    procedure btnEMailClick(Sender: TObject);
    procedure btnCheckClick(Sender: TObject);
    procedure btnRedoPointsClick(Sender: TObject);
    procedure btnAuctionClick(Sender: TObject);
    procedure btnRumorClick(Sender: TObject);
    procedure btnPlayersClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnServeClick(Sender: TObject);
  private
    FFilename : String;
    FThread : TMyThread;
    FEvent : TEvent;
    FEMail : TStringList;
    FLoaded : boolean;
    { Private declarations }
    FPerson  : TPerson;
    FPage  : IDispatch;
    FPoints : TPoints;
    FTo : String;
    FLast : TDateTime;
    FLog : TStringList;
    FProcess : TProcess;
    procedure DoAuction;
    procedure DoPlayers;
    procedure DoPoints;
    procedure Serve;
    procedure Server;
    procedure Wait;
    procedure UpdatePoints(AType : EPlayerType; APlayer : TPlayer); overload;
    procedure UpdatePoints(AType : EPlayerType); overload;
    procedure UpdatePlayer(AType : EPlayerType);
    procedure Process;
    procedure Navigate(ATo : String);
    function  Validate(AUsernamePassword : String; var APlayerNo : Integer) : TPerson;
    function  ValidateSquad(AForm : TFrmDreamTeam; APlus : TPlayer) : Boolean;
  public
    { Public declarations }
    procedure TimeWarp;
  end;

var
  FrmDreamTeamScore: TFrmDreamTeamScore;

implementation

{$R *.DFM}

procedure TFrmDreamTeamScore.UpdatePoints(AType : EPlayerType; APlayer : TPlayer);
const
  Match = '<!-- START CURRENT SEASON MATCH STATS -->' ;
var
  C : Integer;
  lFound : boolean;
  OK : boolean;
  lDate : TDateTime;
  oTeam : TTeam;
  lTeamID : Integer;
  Str  : String;
  Idx,
  P,
  Line : Integer;

  lID : Integer;
  lName : String;
  lCode : Integer;
  lTeam : String;
  lValue : Extended;
  lType : EPlayerType;
  lPoints : Integer;
  lPois : TObjectList;
  Poi : TPoint;
  At : TDateTime;
begin
(*
<H3>Current dream team record</H3>
<UL>
<LI class=points><SPAN>TOTAL POINTS</SPAN><BR>18 </LI>
<LI class=position><SPAN>RANKING (position)</SPAN><BR>2 </LI>
<LI class=overall><SPAN>RANKING (overall)</SPAN><BR>17 </LI></UL>
<TABLE cellSpacing=0>
<COLGROUP>
<COL class=date>
<COL class=match>
<COL class=points>
<THEAD>
<TR>
<TH class=date><A id=ctl00_PopupContentPlaceHolder_rpEvents_ctl00_lbDate href='javascript:WebForm_DoPostBackWithOptions(new WebForm_PostBackOptions("ctl00$PopupContentPlaceHolder$rpEvents$ctl00$lbDate", "", false, "", "?pid=2&amp;ob=ko&amp;sd=1", false, true))'>Date</A></TH>
<TH class=match><A id=ctl00_PopupContentPlaceHolder_rpEvents_ctl00_lbMatch href='javascript:WebForm_DoPostBackWithOptions(new WebForm_PostBackOptions("ctl00$PopupContentPlaceHolder$rpEvents$ctl00$lbMatch", "", false, "", "?pid=2&amp;ob=hcn&amp;sd=0", false, true))'>Match</A></TH>
<TH class=points><A id=ctl00_PopupContentPlaceHolder_rpEvents_ctl00_lbPoints href='javascript:WebForm_DoPostBackWithOptions(new WebForm_PostBackOptions("ctl00$PopupContentPlaceHolder$rpEvents$ctl00$lbPoints", "", false, "", "?pid=2&amp;ob=po&amp;sd=0", false, true))'>Points</A></TH></TR></THEAD>
<TFOOT>
<TR>
<TD colSpan=3>&nbsp;</TD></TR></TFOOT>
<TBODY>
<TR>
<TD class=left>30-08-2008</TD>
<TD>Arsenal&nbsp;v&nbsp;Newcastle</TD>
<TD class=right>5</TD></TR>
<TR class=alt>
<TD class=left>23-08-2008</TD>
<TD>Fulham&nbsp;v&nbsp;Arsenal</TD>
<TD class=right>0</TD></TR>
<TR>
<TD class=left>16-08-2008</TD>
<TD>Arsenal&nbsp;v&nbsp;West Brom</TD>
<TD class=right>13</TD></TR></TBODY></TABLE></DIV></DIV>
<DIV class=pastStats>
<H3>Previous Dream Team record 2007/08</H3>
<TABLE cellSpacing=0>
<COLGROUP>


<DIV class=season0910MatchStats id=season0910MatchStats>
<TABLE class=matchStatsTable cellSpacing=0 cellPadding=0>
<THEAD>
<TR>
<TH colSpan=5><IMG id=ctl00_PopupContentPlaceHolder_rpEvents_ctl00_popupPProfileMatchStat style="BORDER-TOP-WIDTH: 0px; BORDER-LEFT-WIDTH: 0px; BORDER-BOTTOM-WIDTH: 0px; BORDER-RIGHT-WIDTH: 0px" src="App_Themes/EPL/images/tableImages/popup_playerprofilestats.png"></TH></TR></THEAD>
<TFOOT>
<TR>
<TD colSpan=7>&nbsp;</TD></TR></TFOOT>
<TBODY>
<TR>
<TD class=leftBorder></TD>
<TD class=firstRow>Date</TD>
<TD class=firstRow>Match</TD>
<TD class=pointsTop>Points</TD>
<TD class=rightBorder></TD></TR>
<TR>
<TD class=leftBorder></TD>
<TD class=date>15-08-2009</TD>
<TD class=match>Everton&nbsp;v&nbsp;Arsenal</TD>
<TD class=points>0</TD>
<TD class=rightBorder></TD></TR></TBODY></TABLE></DIV><!-- END CURRENT SEASON MATCH STATS --><!-- START SEASON 08/09 GRAPH -->
<DIV class=season0910Graph id=season0809Graph style="DISPLAY: none">
<DIV class=season0910GraphHeader><A href="JavaScript:TogglePlayerProfile('season0809Graph', 'pastStats0708')"><IMG class=viewSwitchButton id=ctl00_PopupContentPlaceHolder_Image3 style="BORDER-TOP-WIDTH: 0px; BORDER-LEFT-WIDTH: 0px; BORDER-BOTTOM-WIDTH: 0px; BORDER-RIGHT-WIDTH: 0px" src="App_Themes/EPL/images/buttons/popup_playerprofilestatsview.png"></A> </DIV>
<DIV class=leftSide>
<DIV class=row>
*)
  lPois := TObjectList.Create(False);

  Line := 0;
  while Line<mmoHTML.Lines.Count do begin
    Str := mmoHTML.Lines[Line];
    P := Pos(Match,Str);
    if (P<>0) then begin
      OK := True;
      Inc(Line,10);
      while OK do begin
        Str := mmoHTML.Lines[Line];
//        if Pos('<TR class=odd>',Str)=0 then
//          exit;
        if (Pos('<TR class=even>',Str)=0) and ((Pos('<TR class=odd>',Str)=0)) then
          exit;

        Str := mmoHTML.Lines[Line+1];
        P := Pos('>',Str);
        Delete(Str,1,P);
        P := Pos('<',Str);
        SetLength(Str,P-1);
        ShortDateFormat := 'dd/mm/yyyy';
        DateSeparator := '/';
        lDate := StrToDate(Replace(Str,'-','/'));

        Str := mmoHTML.Lines[Line+3];
        P := Pos('>',Str);
        Delete(Str,1,P);
        P := Pos('<',Str);
        SetLength(Str,P-1);
        Str := Trim(Str);

        lPoints := StrToInt(Str);

        lPois.Clear;
//        Poi := FPoints.Find(APlayer.PlayerID);
        FPoints.Fill(APlayer.PlayerID,lPois);
        if lPois.Count>0 then begin
          lFound := False;
          for C := 0 to lPois.Count-1 do begin
            Poi := lPois[C] as TPoint;
//        if assigned(Poi) then begin
            if Trunc(Poi.FromAt)=Trunc(lDate) then begin
              if (Poi.Points<>lPoints) then begin
                Poi.Points := lPoints;
              end;
              lFound := True;
              break;
            end;
          end;
          if not lFound then begin
            Poi := TPoint.Create(-1,APlayer.PlayerID,lPoints,0,lDate,2958101);
            FPoints.Add(Poi);
          end;
        end else begin
          Poi := TPoint.Create(-1,APlayer.PlayerID,lPoints,0,lDate,2958101);
          FPoints.Add(Poi);
        end;
        Inc(Line,4);
        Str := mmoHTML.Lines[Line];

        OK := (Pos('<TR class=even>',Str)>0) or ((Pos('<TR class=odd>',Str)>0));
//        OK := (Pos('<TD class=leftBorder>',Str)>0);
      end; {while}
      Line := mmoHTML.Lines.Count;
    end else
      Inc(Line);
  end;    { while }
  lPois.Free;
end;

procedure TFrmDreamTeamScore.UpdatePoints(AType : EPlayerType);
const
  Match = 'ViewPlayerProfile.aspx?pid=';
var
  oTeam : TTeam;
  lTeamID : Integer;
  Str  : String;
  C,
  Idx,
  P,
  Line : Integer;
  Play : TPlayer;

  lID : Integer;
  lName : String;
  lCode : Integer;
  lTeam : String;
  lValue : Extended;
  lType : EPlayerType;
  lPoints : Integer;
  Poi : TPoint;
  At : TDateTime;
begin
{
<TR class=tyellow2s12>
<TD width=60>001</TD><!-- <td width="175"><a href="PlayerProfile?playerid=18236&gameid=183" class="redtoblack12">Lehmann</a></td>-->
<TD class=black12 width=175>Lehmann</TD>
<TD align=middle width=125>Arsenal</TD>
<TD align=middle width=100>£4.0m</TD>
<TD align=middle width=100>5</TD></TR>
<TR class=tyellow2s12>

<TD class=code>002</TD>
<TD class=name><A href="ViewPlayerProfile.aspx?pid=2">M Almunia</A></TD>
<TD class=club>Arsenal</TD>
<TD class=price>£5.0m</TD>
<TD class=points>0</TD></TR>
<TR class=alt>
}
  Line := 0;
  while Line<mmoHTML.Lines.Count do begin
    Str := mmoHTML.Lines[Line];
    P := Pos(Match,Str);
    if (P<>0) then begin
      Str := mmoHTML.Lines[Line];
      Delete(Str,1,P+Length(Match)-1);
      P := Pos('"',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);

      lID := StrToInt(Str);
      Idx := gPlayers.IndexOf(lID,False);
      if Idx=-1 then begin
        ShowMessage('New player!');
        exit;
      end;
      Play := gPlayers[Idx];

      Str := mmoHTML.Lines[Line+4];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);

      lPoints := StrToInt(Str);

//      Poi := FPoints.Find(Play.PlayerID);
//      if assigned(Poi) then begin
//        {Take a note of the points, if they change or if we last looked more than 6 hours ago}
//        if (Poi.Points<>lPoints) or ((Now-Poi.FromAt)>StrToTime('05:30:00')) then begin
//          Poi.UntilAt := Now;
//          Poi := TPoint.Create(-1,Play.PlayerID,lPoints,lPoints-Poi.Points,Now,2958101);
//          FPoints.Add(Poi);
//        end;
//      end else begin
//        Poi := TPoint.Create(-1,Play.PlayerID,lPoints,lPoints,Now,2958101);
//        FPoints.Add(Poi);
//      end;
      Inc(Line,5);
      Play.Points := lPoints;
      
      SetToNil(Play);
    end else
      Inc(Line);
  end;    { while }

  for C := 0 to gPlayers.Count-1 do begin
    Play := gPlayers[C];
    if (Play.PlayerType=AType) and (Play.Used) then begin
      Str := mmoStages.Lines[5];
      Str := Replace(Str,'XXX',IntToStr(Play.Code));
      FFilename := IntToStr(Play.Code)+'.HTM';
      Navigate(Str);
      FFilename := '';
      UpdatePoints(AType,Play);
    end;
    Play := Nil;
  end;
end;

(*
procedure TFrmDreamTeamScore.UpdatePoints(AType : EPlayerType);
const
  Match = 'PlayerProfile?playerid=';
var
  oTeam : TTeam;
  lTeamID : Integer;
  Str  : String;
  Idx,
  P,
  Line : Integer;
  Play : TPlayer;

  lID : Integer;
  lName : String;
  lCode : Integer;
  lTeam : String;
  lValue : Extended;
  lType : EPlayerType;
  lPoints : Integer;
  Poi : TPoint;
  At : TDateTime;
begin
{
<TR class=tyellow2s12>
<TD width=60>001</TD><!-- <td width="175"><a href="PlayerProfile?playerid=18236&gameid=183" class="redtoblack12">Lehmann</a></td>-->
<TD class=black12 width=175>Lehmann</TD>
<TD align=middle width=125>Arsenal</TD>
<TD align=middle width=100>£4.0m</TD>
<TD align=middle width=100>5</TD></TR>
<TR class=tyellow2s12>
}
  Line := 0;
  while Line<mmoHTML.Lines.Count do begin
    Str := mmoHTML.Lines[Line];
    P := Pos(Match,Str);
    if (P<>0) then begin
      Str := mmoHTML.Lines[Line];
      Delete(Str,1,P+Length(Match)-1);
      P := Pos('&',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);

      lID := StrToInt(Str);
      Idx := gPlayers.IndexOf(lID,False);
      if Idx=-1 then begin
        ShowMessage('New player!');
        exit;
      end;
      Play := gPlayers[Idx];

      Str := mmoHTML.Lines[Line+4];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);

      lPoints := StrToInt(Str);

      Poi := FPoints.Find(Play.PlayerID);
      if assigned(Poi) then begin
        {Take a note of the points, if they change or if we last looked more than 6 hours ago}
        if (Poi.Points<>lPoints) or ((Now-Poi.FromAt)>StrToTime('05:30:00')) then begin
          Poi.UntilAt := Now;
          Poi := TPoint.Create(-1,Play.PlayerID,lPoints,lPoints-Poi.Points,Now,2958101);
          FPoints.Add(Poi);
        end;
      end else begin
        Poi := TPoint.Create(-1,Play.PlayerID,lPoints,lPoints,Now,2958101);
        FPoints.Add(Poi);
      end;
      Inc(Line,5);
      Play.Points := lPoints;
      
      SetToNil(Play);
    end else
      Inc(Line);
  end;    { while }
end;
*)
procedure TFrmDreamTeamScore.UpdatePlayer;
const
  Match = 'ViewPlayerProfile.aspx?pid=';
var
  oTeam : TTeam;
  lTeamID : Integer;
  New : Boolean;
  Str  : String;
  Idx,
  P,
  Line : Integer;
  Play : TPlayer;

  lID : Integer;
  lName : String;
  lCode : Integer;
  lTeam : String;
  lValue : Extended;
  lType : EPlayerType;
  lPoints : Integer;
  Poi : TPoint;
  At : TDateTime;
begin
(*
<TR class=tyellow2s12>
<TD width=60>001</TD><!-- <td width="175"><a href="PlayerProfile?playerid=18236&gameid=183" class="redtoblack12">Lehmann</a></td>-->
<TD class=black12 width=175>Lehmann</TD>
<TD align=middle width=125>Arsenal</TD>
<TD align=middle width=100>£4.0m</TD>
<TD align=middle width=100>5</TD></TR>
<TR class=tyellow2s12>


<TR>
<TD class=black12 width=60>001</TD>
<TD class=black12 width=175><A class=link12 href="viewPlayerProfile.do?playerId=1&amp;type=single">Almunia</A></TD>
<TD class=black12 align=middle width=125>Arsenal</TD>
<TD class=black12 align=middle width=100>£1.5m</TD>
<TD class=black12 align=middle width=100>0</TD></TR>
<TR>

<TD class=code>002</TD>
<TD class=name><A href="ViewPlayerProfile.aspx?pid=2">M Almunia</A></TD>
<TD class=club>Arsenal</TD>
<TD class=price>£5.0m</TD>
<TD class=points>0</TD></TR>
<TR class=alt>

<TD>005</TD>
<TD><A id=ctl00_PopupContentPlaceHolder_playerList_rptPlayers_ctl00_hypName href="/fantasyfootball/0910/ViewPlayerProfile.aspx?pid=5">L Fabianski</A></TD>
<TD>Arsenal</TD>
<TD class=centerAlign>0.0</TD>
<TD class=centerAlign>£2.5m</TD>
<TD class="vfm centerAlign lastCol">0</TD>
<TD class=rightBorder></TD></TR>
<TR>

*)
  Line := 0;
  while Line<mmoHTML.Lines.Count do begin
    Str := mmoHTML.Lines[Line];
    P := Pos(Match,Str);
    if (P<>0) then begin
      Str := mmoHTML.Lines[Line-1];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);

      lID := StrToInt(Str);
      Idx := gPlayers.IndexOf(lID,True);
      New := Idx=-1;
      if not New then begin
        Play := gPlayers[Idx];
      end;

      Str := mmoHTML.Lines[Line];
      P := Pos(Match,Str);
      Delete(Str,1,P+Length(Match)-1);
      P := Pos('"',Str);
      lCode := StrToInt(Copy(Str,1,P-1));
//      Inc(Line);

//      Str := mmoHTML.Lines[Line];
      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      lName := Str;
      Inc(Line);

{<TD align=middle width=125>Arsenal</TD>}
      Str := mmoHTML.Lines[Line];
      P := Pos('>',Str);
//      Delete(Str,1,P);
//      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      lTeam := Str;
      Inc(Line);
      Inc(Line);

{<TD align=middle width=100>£4.0m</TD>}
      Str := mmoHTML.Lines[Line];
      P := Pos('>',Str);
//      Delete(Str,1,P);
//      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      lValue := StrToFloat(Copy(Str,2,Length(Str)-2));
      Inc(Line);

{<TD align=middle width=100>0</TD></TR>}
      Str := mmoHTML.Lines[Line];
      P := Pos('>',Str);
//      Delete(Str,1,P);
//      P := Pos('>',Str);
      Delete(Str,1,P);
      P := Pos('<',Str);
      Delete(Str,P,Length(Str)-P+1);
      Str := Trim(Str);
      lPoints := StrToInt(Str);
      
//      lType := EPlayerType(FStage-1);
      lType := AType;
      oTeam := gTeams.Find(lTeam);
      if not assigned(oTeam) then begin
        gTeams.Add(lTeam);
        oTeam := gTeams.Find(lTeam);
      end;
      if New then begin
//        Play.Points1 := StrToInt(Str)
//        EMail('New Player',gsPlayerType[lType]+' '+lName+' of '+lTeam+' now available!',gPersons);
        FEMail.Add('New Player'+gsPlayerType[lType]+' '+lName+' of '+lTeam+' now available!');

        gPaperTalk.InsertItem('-', '-', lName, now, 'New Player', lValue);

        Play := TPlayer.Create(lID,oTeam.TeamID,lCode,lName,lValue,lType,lPoints);
        gPlayers.Add(Play);
      end else begin
        Play.Check(lID,oTeam.TeamID,lCode,lName,lValue,lType,lPoints,FLog);
      end;
      Inc(Line);

      SetToNil(Play);
    end else
      Inc(Line);
  end;    { while }
end;

procedure TFrmDreamTeamScore.Process;
//const
//  PlayerDetails1 = 'http://www.dreamteamfc.com/Sun/servlet/PlayerProfile?playerid=';
//  PlayerDetails1 = 'http://www.dreamteamfc.com/dtfc04/servlet/PlayerProfile?playerid=';
//  PlayerDetails2 = '&gameid=86';
//  PlayerDetails2 = '&gameid=167';
begin
//  if FStage>=100 then begin
//    if FStage=100 then begin
//      Navigate(mmoStages.Lines[0]);
//    end else begin
//      case FStage of
//        101 :
//          begin
//            FCount := 0;
//            Navigate(mmoStages.Lines[Ord(gPlayers[FCount].PlayerType)+1]);
//            FCount := -1;
//          end;
//        102,
//        103 :
//          begin
//            if (FCount<gPlayers.Count) then begin
//              FStage := 102;
//              while FileExists('HTML\'+IntToStr(gPlayers[FCount].Code)+'.TXT') do begin
//                Inc(FCount);
//                if FCount>=gPlayers.Count then begin
//                  Screen.Cursor := crDefault;
//                  btnUpdate.Enabled := True;
//                  exit;
//                end;
//              end;  
//              Navigate(PlayerDetails1+IntToStr(gPlayers[FCount].Code)+PlayerDetails2);
//            end else begin
//              Screen.Cursor := crDefault;
//              btnUpdate.Enabled := True;
//            end;
//          end;
//      end;
//    end;    { case }
//  end else begin
//    if mmoStages.Lines.Count>FStage then
//      Navigate(mmoStages.Lines[FStage])
//    else begin
//      gPlayers.Sort;
//      gPlayers.Save;
//
//      FPoints.Save;
//      FPoints.Free;
//      Screen.Cursor := crDefault;
//      btnUpdate.Enabled := True;
//
//      if FUpdated and (ParamStr(1)='/Update') then
//        btnEMail.Click
//      else if ParamCount<>0 then
//        Application.Terminate;
//    end;
//  end;
end;

procedure TFrmDreamTeamScore.Navigate(ATo : String);
begin
  FLoaded := False;
  FTo := ATo;
  webBrowse.Navigate(ATo);
  FProcess := Wait;
  repeat
    Sleep(100);
    Application.ProcessMessages;
  until FLoaded;
  FProcess := Nil;
end;

procedure TFrmDreamTeamScore.TimeWarp;
var
  Qry : TOraQuery;
begin
  if FLast=0 then begin
    Qry := TOraQuery.Create(Self);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('SELECT MAX(FROMAT) FROM POINTS');
      Open;
      FLast := Max(FLast,Fields[0].AsDateTime);
      Close;
      Clear;
      Add('SELECT MAX(FROMAT) FROM SQUAD');
      Open;
      FLast := Max(FLast,Fields[0].AsDateTime);
      Close;
    end;
  end;
//  if Now<FLast then begin
  if (FLast-Now)>StrToTime('00:15:00') then begin
    MessageDlg('Cheat!',mtError,[mbOK],0);
    Application.Terminate;
    FLast := Max(FLast,Now);
  end;
end;

procedure TFrmDreamTeamScore.btnUpdateClick(Sender: TObject);
begin
  DoPoints;
end;

procedure TFrmDreamTeamScore.DoPoints;
var
  lType : EPlayerType;
begin
  Label1.Caption := 'Updating points...';
  btnUpdate.Enabled := False;

  FPoints := TPoints.Create;
  FPoints.Load(True);

  Screen.Cursor := crHourGlass;
  webBrowse.BringToFront;

  Navigate(mmoStages.Lines[0]);
  for lType := ptGoalKeeper to ptStriker do begin
    FFilename := gsPlayerType[lType]+'.HTM';
    Navigate(mmoStages.Lines[Ord(lType)+1]);
    FFilename := '';
    UpdatePoints(lType);
  end;

  FPoints.Save;
  FPoints.Free;

  gPlayers.Save;

  Screen.Cursor := crDefault;
  Label1.Caption := 'Updating points...Done';
end;

procedure TFrmDreamTeamScore.webBrowseNavigateComplete2(Sender: TObject; const pDisp: IDispatch; var URL: OleVariant);
begin
  if FPage = nil then
    FPage := pDisp; { save for comparison }
end;

procedure TMyThread.Serve;
begin
  FForm.Serve;
end;

constructor TMyThread.Create(ASuspended : Boolean);
begin
  inherited Create(ASuspended);
  FEvent := TEvent.Create(Nil,False,False,'DTTock');
end;

destructor TMyThread.Destroy;
begin
  FEvent.Free;
  inherited;
end;

procedure TMyThread.Execute;
var
  lNow,
  lThen : TDateTime;
begin
  lThen := Now-StrToTime('01:01:00');
  repeat
    lNow := Now;
    if (lNow-lThen)>StrToTime('01:00:00') then begin
      Synchronize(Serve);
      lThen := Now;
    end;
  until FEvent.WaitFor(100) in [wrSignaled,wrAbandoned,wrError];
end;

procedure TFrmDreamTeamScore.Server;
var
  lThread : TMyThread;
begin
  lThread := TMyThread.Create(True);
  lThread.Form := Self;
  FEvent := lThread.Event;
  lThread.FreeOnTerminate := True;
  lThread.Resume;
end;

procedure TFrmDreamTeamScore.Wait;
begin
  FLoaded := True;
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
    if assigned(FProcess) then
      FProcess;
//    if FStage<100 then
    if FFilename<>'' then
      mmoHTML.Lines.SaveToFile('HTML\'+FFilename);

//    mmoHTML.Lines.SaveToFile('HTML\'+FormatDateTime('YYYYMMDDHHMMSS',Now)+'.HTM');
//    else if FStage=102 then
//      mmoHTML.Lines.SaveToFile('HTML\'+Format('%5.5d.txt',[gPlayers[FCount].Code]));
//    try
//      if FStage<100 then
//        Parse
//      else
//        Parse2;
//    except
//      asm nop end;
//    end;
//    Inc(FStage);
//    Inc(FCount);
//    Process;
    FPage := nil; {clear the global variable }
  end;
end;

procedure TFrmDreamTeamScore.FormCreate(Sender: TObject);
var
  Frm : TFrmLogin;
  Frm2 : TFrmDreamTeam;
begin
  FEMail := TStringList.Create;
  FLast := 0;

  gTeams := TTeams.Create;
  gTeams.Load;
  gPlayers := TPlayers.Create;
  gPlayers.Load;
  gPersons := TPersons.Create;
  gPersons.Load;

  TimeWarp;

  if ParamStr(1) = 'auction' then
  begin
    Show;
//    btnPlayers.Click;
//    btnUpdate.Click;
//    btnAuction.Click;
//    Application.close;
  end;

  if ParamStr(3)='Pts' then begin
    Show;
    btnUpdate.Click;
  end else if ParamStr(3)='Oy' then begin
    Show;
    btnAuction.Click;
  end else if ParamStr(3)='Tick' then begin
    Server;
    Show;
  end else begin
    Frm := TFrmLogin.Create(Self);
    case Frm.ShowModal of
      mrOK : FPerson := Frm.Person;
      mrCancel : Application.Terminate;
    end;
    Frm.Free;

    if assigned(FPerson) then begin
      if (FPerson.UserName='Woolley') or (FPerson.UserName='Richard') then
        Show;
      Frm2 := TFrmDreamTeam.Create(Self);
      FrmDreamTeam := Frm2;
      Frm2.PersonID := FPerson.ID;
      Frm2.Show;
    end;
  end;
end;

procedure TFrmDreamTeamScore.FormDestroy(Sender: TObject);
begin
  gPersons.Free;
  gPlayers.Free;
  gTeams.Free;
  FEMail.Free;
end;

{
procedure TFrmDreamTeamScore.Save;
begin
  gPlayers.Save;
end;

procedure TFrmDreamTeamScore.Load;
begin
  gPlayers.Clear;
  gPlayers.Load;
end;
}
(*
procedure TFrmDreamTeamScore.Edit;
begin
  gPlayers.Clear;
  gPlayers.Load;

  dxmData.Open;
  while not dxmData.Eof do begin
    dxmData.Delete;
  end;    { while }
  for C := 0 to gPlayers.Count-1 do { Iterate } begin
    dxmData.Append;
    dxmData.FieldByName('ID').AsInteger := gPlayers[C].ID;
    dxmData.FieldByName('NAME').AsString := gPlayers[C].Name;
    dxmData.FieldByName('TEAM').AsString := gPlayers[C].Team;
    dxmData.FieldByName('COST').AsFloat := gPlayers[C].Price;
//    dxmData.FieldByName('POINTS1').AsInteger := gPlayers[C].Points1;
//    dxmData.FieldByName('POINTS2').AsInteger := gPlayers[C].Points2;
//    dxmData.FieldByName('POINTS3').AsInteger := gPlayers[C].Points3;
    dxmData.Post;
  end;    { for }
  grdData.BringToFront;
end;
*)

(*
procedure TFrmDreamTeamScore.Display;
var
  C : Integer;
begin
  mmoHTML.Clear;
  for C := 0 to gPlayers.Count-1 do { Iterate } begin
    mmoHTML.Lines.Add(IntToStr(gPlayers[C].PlayerID)+' '+gPlayers[C].Name+' '+gPlayers[C].Team+' '+FloatToStr(gPlayers[C].Price){+' '+IntToStr(gPlayers[C].Points1)+' '+IntToStr(gPlayers[C].Points2)+' '+IntToStr(gPlayers[C].Points3)});
  end;    { for }
end;
*)

const
  colID = 27; {AA}
  colName = 28;
  colTeam = 29;
  colPrice = 30;
  colPoints1 = 31;
  colPoints2 = 32;
  colPoints3 = 33;

procedure TFrmDreamTeamScore.btnToExcelClick(Sender: TObject);
begin
(*
var
  C : Integer;
  Excel : TExcel;
  {}
  Excel := TExcel.Create;
  try
    try
      Screen.Cursor := crHourGlass;
      Excel.Open(edtXLS.Text,foExcel);

      for C := 0 to gPlayers.Count-1 do { Iterate } begin
        Excel.Cell[colID,C+2] := gPlayers[C].ID;
        Excel.Cell[colName,C+2] := gPlayers[C].Name;
        Excel.Cell[colTeam,C+2] := gPlayers[C].Team;
        Excel.Cell[colPrice,C+2] := gPlayers[C].Price;
//        Excel.Cell[colPoints1,C+2] := gPlayers[C].Points1;
//        Excel.Cell[colPoints2,C+2] := gPlayers[C].Points2;
//        Excel.Cell[colPoints3,C+2] := gPlayers[C].Points3;
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
*)
end;

procedure TFrmDreamTeamScore.btnWebClick(Sender: TObject);
const
  C : Integer = 0;
begin
  Inc(C);
  if C>2 then
    C := 1;
  case C of
    1 : webBrowse.BringToFront;
    2 : mmoHTML.BringToFront;
//    3 : grdData.BringToFront;
  end;
end;

procedure TFrmDreamTeamScore.grdDataEdited(Sender: TObject; Node: TdxTreeListNode);
//var
//  Idx : Integer;
//  Play : TPlayer;
begin
//  Node;
//  Idx := gPlayers.IndexOf(Node.Values[1]);
//  Idx := gPlayers.IndexOf(Node.Values[0]);
//  Play := gPlayers[Idx];
//  Play.Points1 := Node.Values[5];
//  Play.Points2 := Node.Values[6];
//  Play.Points3 := Node.Values[7];
end;

procedure TFrmDreamTeamScore.btnDetailsClick(Sender: TObject);
var
  lPlayer : TPlayer;
  C : Integer;
begin
  {look up the details on all the players!
   https://www.dreamteamfc.com/Sun/servlet/PlayerProfile?playerid=4226&gameid=86
  }
  btnUpdate.Enabled := False;

  Screen.Cursor := crHourGlass;
  webBrowse.BringToFront;

  {Have to go to this page first!}
  Navigate(mmoStages.Lines[0]);
  for C := 0 to gPlayers.Count-1 do begin
    lPlayer := gPlayers[C];
    Navigate(Replace(mmoStages.Lines[5],'XXX',IntToStr(lPlayer.Code)));
    lPlayer := Nil;
  end;

  Screen.Cursor := crDefault;
end;

procedure TFrmDreamTeamScore.btnRetryClick(Sender: TObject);
begin
  webBrowse.Navigate(FTo);
end;

procedure TFrmDreamTeamScore.btnReParseClick(Sender: TObject);
const
  MatchName = '<TD align=middle><SPAN class=whitebold12>';
  MatchNotes = '<TD vAlign=top width=334><SPAN class=black12>';
  Match = 'Last Season''s Record';
var
  C : Integer;
  Pla : TPlayer;
  P,
  Line : Integer;
  Str : String;
  lValue : Extended;
  lPoints : Integer;
  lNotes : String;
begin
  {}
  for C := 0 to gPlayers.Count-1 do { Iterate } begin
    Pla := gPlayers[C];
(*
<TABLE cellSpacing=0 cellPadding=5 width="100%" border=0>
<TBODY>
<TR bgColor=#4a9753>
<TD width=100><SPAN class=whitebold12>001</SPAN></TD>
<TD align=middle><SPAN class=whitebold12>Seaman</SPAN></TD></TR>
<TR bgColor=#bcdec1>
<TD class=blackbold12 align=middle>Arsenal</TD>
<TD class=blackbold12 align=middle>£3.5m</TD></TR></TBODY></TABLE></TD>
<TD width=89><IMG height=47 src="/newsint/FC02/html/ENGLISH/Images/DT0203-001.gif" width=94></TD></TR></TBODY></TABLE><BR>
<TABLE cellSpacing=0 cellPadding=0 width=460 align=center border=0>
<TBODY>
<TR>
<TD vAlign=top width=126><IMG height=126 src="/newsint/FC02/html/ENGLISH/Images/DT0203-001.jpg" width=100> </TD>
<TD vAlign=top width=334><SPAN class=black12>The Gunners No1 only played 17 league games last season due to back and shoulder problems, but nevertheless 'Safe Hands' still managed to pick up 99 points. Returning from World Cup disappointment, Seaman will be hoping to take his appearance tally past 550 in his 12th Highbury season and help last year's double winners to European silverware during this campaign. </SPAN></TD></TR></TBODY></TABLE><BR>
<TABLE cellSpacing=1 cellPadding=2 width=460 align=center border=0>
<TBODY>
<TR bgColor=#4a9753>
<TD colSpan=4><SPAN class=whitebold12>This Season's Record ('02/'03)</SPAN></TD></TR>
<TR bgColor=#78b4ff>
<TD class=whitebold12 width=125 bgColor=#4a9753>Price Tag:</TD>
<TD class=black12 align=middle width=125 bgColor=#bcdec1>£3.5m</TD>
<TD width=140 bgColor=#4a9753><SPAN class=whitebold12>Ranking </SPAN><SPAN class=white10>(position)</SPAN></TD>
<TD class=black12 align=middle width=110 bgColor=#bcdec1><!--1--></TD></TR>
<TR bgColor=#78b4ff>
<TD class=whitebold12 width=125 bgColor=#4a9753>Total Points:</TD>
<TD class=black12 align=middle width=125 bgColor=#bcdec1>-<!--0--></TD>
<TD width=140 bgColor=#4a9753><SPAN class=whitebold12>Ranking </SPAN><SPAN class=white10>(overall)</SPAN></TD>
<TD class=black12 align=middle width=110 bgColor=#bcdec1>-<!--156--></TD></TR></TBODY></TABLE><BR>
<TABLE cellSpacing=1 cellPadding=2 width=460 align=center background=/newsint/FC02/html/ENGLISH/Images/bgthis.gif border=0>
<TBODY>
<TR bgColor=#4a9753>
*)

    lValue := 0; if lValue=0 then ;
    lPoints := 0; if lPoints=0 then ;
    lNotes := '';
    
    mmoHTML.Lines.LoadFromFile(Format('%03d.txt',[C+101]));
    Line := 0;
    while Line<mmoHTML.Lines.Count do begin
      Str := mmoHTML.Lines[Line];

      P := Pos(MatchName,Str);
      if P<>0 then begin
        {Check Name is correct!}
        Delete(Str,1,P+Length(MatchName)-1);
        P := Pos('<',Str);
        Delete(Str,P,Length(Str)-P+1);
        if Str<>Pla.Name then begin
          ShowMessage(IntToStr(C));
          exit;
        end;
      end;

      Str := mmoHTML.Lines[Line];
      P := Pos(MatchNotes,Str);
      if P<>0 then begin
        Delete(Str,1,P+Length(MatchNotes)-1);
        P := Pos('<',Str);
        while P=0 do begin
          Inc(Line);
          Str := Str + mmoHTML.Lines[Line];
          P := Pos('<',Str);
        end;    { while }
        Delete(Str,P,Length(Str)-P+1);
        lNotes := Str;
      end;

      Str := mmoHTML.Lines[Line];
      P := Pos(Match,Str);
      if P<>0 then begin
        Inc(Line,3);
        Str := mmoHTML.Lines[Line];
        P := Pos('>',Str);
        Delete(Str,1,P);
        P := Pos('<',Str);
        Delete(Str,P,Length(Str)-P+1);
        Str := Trim(Copy(Str,2,Length(Str)-2));
        try
          lValue := StrToFloat(Str);
        except
          lValue := 0;
        end;
        Inc(Line,5);

        Str := mmoHTML.Lines[Line];
        P := Pos('>',Str);
        Delete(Str,1,P);
        P := Pos('<',Str);
        Delete(Str,P,Length(Str)-P+1);
        Str := Trim(Str);
        try
          lPoints := StrToInt(Str);
        except
          lPoints := 0;
        end;

        Line := mmoHTML.Lines.Count;
      end else
        Inc(Line);
    end;    { while }
  end; {for}
end;

procedure TFrmDreamTeamScore.btnPackClick(Sender: TObject);
var
  lPoints : TPoints;
  C,D : Integer;
  Poi1 : TPoint;
  Poi2 : TPoint;
begin
  {Pack the results database...}
  lPoints := TPoints.Create;
  lPoints.Load(True);

  for C := 0 to lPoints.Count-1 do { Iterate } begin
    Poi1 := lPoints[C];
    for D := C+1 to lPoints.Count-1 do begin
      Poi2 := lPoints[D];
      if (Poi1.PlayerID=Poi2.PlayerID) and
         (Poi1.UntilAt=Poi2.FromAt) and
         (Poi1.Delta=0) and (Poi2.Delta=0) and
         (Poi1.Points=Poi2.Points) then begin
        Poi2.FromAt := Poi1.FromAt;
        Poi1.Delete := True;
        break;
      end;
    end;
  end;    { for }

  lPoints.Save;
  lPoints.Free;
end;

procedure TFrmDreamTeamScore.btnEMailClick(Sender: TObject);
var
  C : Integer;
  Frm : TFrmDreamTeam;
  Per : TPerson;
  Count : Integer;
///////////////////////////CW  Rcp : TIdEMailAddressItem;
//  Filename,
//  Name : OleVariant;
//  Mail : MailItem;
//  Mail : TMailMessage;
//  SMTP : TSMTP2000;
//  Stream : TMemoryStream;
//  Lst : TStringList;
begin
////  EMail('Test','Hello',gPersons);
////  exit;
////
////  {Get the results then e-mail them to the people who have requested the info}
////
////  Frm := TFrmDreamTeam.Create(Self);
////  Frm.PersonID := -1;
////  Frm.Show;
////  Frm.pagMain.ActivePageIndex := 2; {Overall page}
////  Frm.grdOverall.SaveToHTML('html\overall'+Format('%8.0f',[Date])+'.HTML',True);
////  Frm.Free;
//////  Name := 'SCORE'+Format('%8.0f',[Date])+'.HTML';
//////  FileName := '\\jrbxp\data\SCORE'+Format('%8.0f',[Date])+'.HTML';
////(*
////  for C := 0 to gPersons.Count-1 do { Iterate } begin
////    Per := gPersons[C];
////    if Per.EMail<>'' then begin
////      Mail := OutApp.CreateItem(olMailItem) as MailItem;
////      Mail.To_ := Per.EMail;
////      Mail.Body := 'Ey up ere''s the latest football scores...';
////      Mail.Attachments.Add(FileName,olByValue,1,Name);
////      Mail.Send;
////      Mail := Nil;
////    end;
////  end;    { for }
////*)
////
////(*
////  for C := 0 to gPersons.Count-1 do { Iterate } begin
////    Per := gPersons[C];
////    if Per.EMail<>'' then begin
////      Mail := TMailMessage.Create(Nil);
////      SMTP := TSMTP2000.Create(Nil);
////      SMTP.Host := '90.0.0.1';
////      SMTP.Port := 6025;
////      SMTP.Connect;
////      if SMTP.SessionConnected then begin
////        Mail.AddTo(Per.UserName,Per.EMail);
////        Mail.SetFrom('Daemon','postmaster@lablogic.com');
////        Mail.Subject := 'Latest football score...';
////        Mail.Date := Now;
////        Mail.AttachFile('\\jrbxp\data\SCORE'+Format('%8.0f',[Date])+'.HTML');
//////        Mail.SetTextPlain(Lst);
////        Mail.RebuildBody;
////        SMTP.MailMessage := Mail;
////        if not SMTP.SendMessage then
////          Beep;
//////        SMTP.Quit;
////      end else
////        Beep;
////      SMTP.Quit;
////      SMTP.Free;
////      Mail.Free;
////    end;
////  end;    { for }
////*)
////  Count := 0;
////  SMTPMsg.Clear;
////  for C := 0 to gPersons.Count-1 do { Iterate } begin
////    Per := gPersons[C];
////    if Per.EMail<>'' then begin
////      SMTPMsg.From.Name := 'beasty';
////      SMTPMsg.From.Address := 'beasty@moatingodseye.co.uk';
////      Rcp := SMTPMsg.Recipients.Add;
////      Rcp.Name := Per.UserName;
////      Rcp.Address := Per.EMail;
////      Inc(Count);
////    end;
////  end;
////  if Count>0 then begin
////    SMTPMsg.Subject := 'Latest football score...';
//////2007    TIdAttachment.Create(SMTPMsg.MessageParts, 'html\overall'+Format('%8.0f',[Date])+'.HTML');
////    SMTP.Connect;
////    SMTP.Send(SMTPMsg);
////    SMTP.Disconnect;
////  end;
////
////  if ParamCount<>0 then
////    Application.Terminate;
end;

function TFrmDreamTeamScore.Validate(AUsernamePassword : String; var APlayerNo : Integer) : TPerson;
var
  P : Integer;
  C : Integer;
  User,
  Pass : String;
  Per : TPerson;
begin
  result := Nil;

  AUsernamePassword := Trim(AUsernamePassword)+'/-1/';
  P := Pos('/',AUsernamePassword);
  User := Copy(AUsernamePassword,1,P-1);
  Delete(AUsernamePassword,1,P);
  P := Pos('/',AUsernamePassword);
  Pass := Copy(AUsernamePassword,1,P-1);
  Delete(AUsernamePassword,1,P);
  P := Pos('/',AUsernamePassword);
  try
    APlayerNo := StrToInt(Copy(AUsernamePassword,1,P-1));
  except
    APlayerNo := -1;
  end;
  for C := 0 to gPersons.Count-1 do { Iterate } begin
    Per := gPersons[C];
    if (Per.Username=User) and (Per.Password=Pass) then begin
      result := Per;
      break;
    end;
  end;    { for }
end;

function TFrmDreamTeamScore.ValidateSquad(AForm : TFrmDreamTeam; APlus : TPlayer) : Boolean;
//var
//  C : Integer;
//  Sqa : TSquad;
//  Price : Extended;
//  Def,
//  Goa,
//  Mid,
//  Str : Integer;
begin
//  Def := 0;
//  Goa := 0;
//  Mid := 0;
//  Str := 0;
//  Price := 0;
//  if assigned(APlus) then begin
//    case APlus.PlayerType of
//      ptMidFielder : Inc(Mid);
//      ptStriker    : Inc(Str);
//      ptDefender   : Inc(Def);
//      ptGoalKeeper : Inc(Goa);
//    end;
//    Price := APlus.Price;
//  end;
//  for C := 0 to AForm.Team.Squad.Count-1 do { Iterate } begin
//    Sqa := AForm.Team.Squad[C] as TSquad;
//    if Sqa.UntilAt<Now then
//      Continue;
//
//    case Sqa.Player.PlayerType of
//      ptMidFielder : Inc(Mid);
//      ptStriker    : Inc(Str);
//      ptDefender   : Inc(Def);
//      ptGoalKeeper : Inc(Goa);
//    end;
//  end;    { for }
//
//  result := ((AForm.Team.Price+Price)<=cTotalPrice) and
//            ((Mid+Str+Def+Goa)<=11);
//  if (Mid+Str+Def+Goa)=11 then
//    result := result and ((Goa=1) and (Def=4) and (((Mid=4) and (Str=2)) or ((Mid=3) and (Str=3))));
//
//  {Just ensure same player not used twice!}
//  for C := 0 to AForm.Team.Squad.Count-1 do { Iterate } begin
//    Sqa := AForm.Team.Squad[C] as TSquad;
//    if (Sqa.Player.PlayerID=APlus.PlayerID) and (Sqa.UntilAt>Now) then begin
//      result := False;
//      break;
//    end;
//  end;    { for }
end;

procedure TFrmDreamTeamScore.btnCheckClick(Sender: TObject);
var
  Qry : TOraQuery;
  F : TextFile;
begin
  AssignFile(F,'PLAYERS.TXT');
  Rewrite(F);
  Qry := TOraQuery.Create(Self);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('select');
    Add('sum(delta) as points, p.playerid');
    Add('from');
    Add('points p');
    Add('group by p.playerid');

    Open;
    while not Eof do begin
      Writeln(F,FieldByName('PLAYERID').AsString,',',FieldByName('POINTS').AsString);
      Next;
    end;    { while }
    Close;
  end;    { with }
  Qry.Free;
  CloseFile(F);
end;

procedure TFrmDreamTeamScore.btnRedoPointsClick(Sender: TObject);
//var
//  S : String;
//  P : Integer;
begin
//  if dlgOpen.Execute then begin
//    try
//      FPoints := TPoints.Create;
//      FPoints.Load(False);
//      
//      mmoHTML.Lines.LoadFromFile(dlgOpen.Filename);
//      S := dlgOpen.Filename;
//      P := Pos('-',S);
//      Delete(S,1,P);
//      P := Pos('.',S);
//      Delete(S,P,Length(S)-P+1);
//      FStage := StrToInt(S);
//      UpdatePoints;
//      
//      FPoints.Save;
//    
//      gPlayers.Sort;
//      gPlayers.Save;
//    finally
//      FPoints.Free;
//    end;
//  end;  
end;

procedure TFrmDreamTeamScore.btnAuctionClick(Sender: TObject);
begin
  DoAuction;
end;

procedure TFrmDreamTeamScore.DoAuction;
var
  Qry : TOraQuery;
  lSquads : TSquads;
  lOthers : TSquads;
  lMax,
  l2nd,
  lSquad : TSquad;
  zSquad : TSquad;
  lPlayers : TPlayers;
  lPlayer : TPlayer;
  C,D,E,F : Integer;
  LRandom : integer;
begin
  Label1.Caption := 'Auctioning players...';
  FEMail.Clear;

  {Finish an auction}
  {Find the highest bid for a player and give him to that team,
   flag all the other bids as failed, flag any teams which are valid}

  lSquads := TSquads.Create;
  lOthers := TSquads.Create(False);
  lPlayers := TPlayers.Create(False);

  {List of all the players bid for...}
  Qry := TOraQuery.Create(Self);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('SELECT * FROM SQUAD WHERE VALID=:VALID AND UNTILAT>:UNTILAT ORDER BY FROMAT');
    ParamByName('VALID').AsString := gcTorF[False];
    ParamByName('UNTILAT').AsDateTime := Now;
    Open;
    while not Eof do begin
      lSquad := TSquad.Create;
      lSquad.Load(Qry);
      lSquads.Add(lSquad);
      Next;
    end;    { while }
    Close;
  end;    { with }

  for C := 0 to lSquads.Count-1 do begin
    lSquad := lSquads[C];
    if not assigned(lPlayers.Find(lSquad.PlayerID)) then begin
      lPlayer := gPlayers.Find(lSquad.PlayerID);
      lPlayers.Add(lPlayer);
    end;
  end;

  dmData.Start;
  try
    {We have a list of the players for which there are bids find the largest and second largest for each}
    for C := 0 to lPlayers.Count-1 do begin
      lPlayer := lPlayers[C];
      lMax := Nil;
      l2nd := Nil;
      for D := 0 to lSquads.Count-1 do begin
        lSquad := lSquads[D];
        if lSquad.PlayerID=lPlayer.PlayerID then begin
          if lSquad.Bid<lPlayer.Price then
            Continue;
          if assigned(lMax) then begin
            if lSquad.Bid>lMax.Bid then begin
              lOthers.Add(lMax);
              l2nd := lMax;
              lMax := lSquad
            end else begin
              if assigned(l2nd) then begin
                if lSquad.Bid>l2nd.Bid then begin
                  lOthers.Add(l2nd);
                  l2nd := lSquad;
                end;
              end else begin
                l2nd := lSquad;
                lOthers.Add(l2nd);
              end;
            end;
          end else begin
            lMax := lSquad;
          end;
        end;
      end;
      if assigned(lMax) then begin
        {Mark winner, delete losers}
        if assigned(l2nd) then begin
  //        EMail('Auction',gsPlayerType[lPlayer.PlayerType]+' '+lPlayer.Name+' could not agree terms!',gPersons.Find(lTeams.Find(l2nd.TeamID).PersonID));
  //        EMail('Auction',gsPlayerType[lPlayer.PlayerType]+' '+lPlayer.Name+' is looking forward to working with you!',gPersons.Find(lTeams.Find(lMax.TeamID).PersonID));
  //        DoAudit(gPersons.Find(lTeams.Find(lMax.TeamID).PersonID).Username,'Won '+lPlayer.Name+' bid '+Format('£%4.1f',[lMax.Bid])+' nearest was '+
  //                gPersons.Find(lTeams.Find(l2nd.TeamID).PersonID).Username+' bid '+Format('£%4.1f',[l2nd.Bid])+'.')
        end else begin
  //        EMail('Auction',gsPlayerType[lPlayer.PlayerType]+' '+lPlayer.Name+' is looking forward to working with you!',gPersons.Find(lTeams.Find(lMax.TeamID).PersonID));
  //        DoAudit(gPersons.Find(lTeams.Find(lMax.TeamID).PersonID).Username,'Won '+lPlayer.Name+' bid '+Format('£%4.1f',[lMax.Bid])+' no other bids.');
        end;
  //      EMail('Auction',gsPlayerType[lPlayer.PlayerType]+' '+lPlayer.Name+' has joined '+lTeams.Find(lMax.TeamID).Name,gPersons);

        LRandom := round(Random(15));
        if LRandom = 4 then
          gPaperTalk.InsertItem(gPersons.Find(lMax.PersonID).UserName, gPersons.Find(lMax.PersonID).Team, lPlayer.Name, now, 'Auction winner', lMax.Bid);
        if LRandom = 5 then
          gPaperTalk.InsertItem(gPersons.Find(lMax.PersonID).UserName, gPersons.Find(lMax.PersonID).Team, 'Undisclosed', now, 'Auction winner', lMax.Bid);
        if (LRandom = 6) or (LRandom = 7) or (LRandom = 8)  then
          gPaperTalk.InsertItem(gPersons.Find(lMax.PersonID).UserName, gPersons.Find(lMax.PersonID).Team, lPlayer.Name, now, 'Undisclosed fee', 0);
        if (LRandom = 9) or (LRandom = 10) or (LRandom = 11)  then
          gPaperTalk.InsertItem('Undisclosed', 'Undisclosed', lPlayer.Name, now, 'Auction winner', lMax.Bid);
        if (LRandom > 11) then
          gPaperTalk.InsertItem(gPersons.Find(lMax.PersonID).UserName, gPersons.Find(lMax.PersonID).Team,'Unknown', now, 'In the transfer market again', 0);


        if (lMax.Bid > (lPlayer.Price*1.2)) and (LRandom < 7) then
          gPaperTalk.InsertItem(gPersons.Find(lMax.PersonID).UserName, gPersons.Find(lMax.PersonID).Team, lPlayer.Name, now, 'Auction Big bid', lMax.Bid);

        if assigned(l2nd) and (l2nd.Bid > lPlayer.Price) then
          gPaperTalk.InsertItem(gPersons.Find(l2nd.PersonID).UserName, gPersons.Find(l2nd.PersonID).Team, lPlayer.Name, now, 'Auction loser', l2nd.Bid);

        lMax.FromAt := Now;
        lMax.Valid := True;
        {Winning bid is 2nd or Player price if no one else bid}
  (*
        if assigned(l2nd) and (lMax.Bid>l2nd.Bid) then
          lMax.Bid := l2nd.Bid
        else
          lMax.Bid := lPlayer.Price;
  *)
      end;
      for D := 0 to lOthers.Count-1 do begin
        lSquad := lOthers[D];
//        if lSquad<>l2nd then
//          EMail('Auction',gsPlayerType[lPlayer.PlayerType]+' '+lPlayer.Name+' was disgusted by your offer!',gPersons.Find(lTeams.Find(lSquad.TeamID).PersonID));
//        lSquad.Valid := False;
        lSquad.Delete;
        {Put the replaced player back into the squad}
//        for E := 0 to lTeams.Count-1 do begin
//          lTeam := lTeams[E];
//          if lTeam.TeamID=lSquad.TeamID then begin
//            for F := 0 to lTeam.Squad.Count-1 do begin
//              zSquad := lTeam.Squad[F] as TSquad;
//              if zSquad.SquadID=lSquad.SquadID then begin
//                zSquad.UntilAt := cForever;
//                zSquad.ReplaceID := -1;
//                zSquad.Player.InTeam := True;
//                zSquad.Player.Save;
//                zSquad.Save;
//                break;
//              end;
//              zSquad := Nil;
//            end;
//          end;
//          lTeam := Nil;
//        end;
      end;
      if assigned(lMax) then begin
        lMax.Save;
        lPlayer.Used := True;
        lPlayer.Save;
      end;
//      lMax.Player.InTeam := True;
//      lMax.Player.Save;
    end;

//    lSquads.Save;

    {Delete losers}
    with Qry,SQL do begin
      Clear;
      Add('DELETE FROM SQUAD WHERE VALID=:VALID');
  {$IFDEF Paradox}
      ParamByName('VALID').AsBoolean := False;
  {$ELSE}
      ParamByName('VALID').AsString := gcTorF[False];
  {$ENDIF}
      ExecSQL;
    end;    { with }
    Qry.Free;

    lOthers.Free;
    lSquads.Free;
    lPlayers.Free;

    {Ensure teams are flagged valid or invalid correctly}
//    for C := 0 to lTeams.Count-1 do begin
//      lTeam := lTeams[C];
//      lTeam.Check;
//      lTeam.Save;
//    end;
//    lTeams.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;

  if FEMail.Count>0 then
    EMail('Auction',FEMail.Text,gPersons);
  Label1.Caption := 'Auctioning players...Done';
end;

procedure TFrmDreamTeamScore.btnRumorClick(Sender: TObject);
var
  R : Integer;
  lTeams : TTeams;
  lTeam : TTeam;
  lSquad : TSquad;
  lType : EPlayerType;
  lPlayer : TPlayer;
begin
  {}
//  Randomize;
//  R := Random(100);
//  if R>75 then begin
//    lTeams := TTeams.Create;
//    lTeams.Load;
//    R := Random(lTeams.Count);
//    lTeam := lTeams[R];
//    repeat
//      R := Random(lTeam.Squad.Count);
//      lSquad := lTeam.Squad[R] as TSquad;
//    until lSquad.Valid and (lSquad.UntilAt>Now);
//    lPlayer := lSquad.Player;
//    lType := lPlayer.PlayerType;
//    EMail('Player Change',gsPlayerType[lPlayer.PlayerType]+' '+lPlayer.Name+' of '+lPlayer.Team+' may be available after the next auction!',gPersons);
//    
//    repeat
//      R := Random(gPlayers.Count);
//      lPlayer := gPlayers[R];
//    until (lPlayer.InTeam=False) and (lType=lPlayer.PlayerType);
//    EMail('Player Change','It is rumoured that '+gsPlayerType[lPlayer.PlayerType]+' '+lPlayer.Name+' of '+lPlayer.Team+' may be moving to '+lTeam.Name+'.',gPersons);
//    
//    lTeams.Free;
//  end;
//  if ParamCount<>0 then
//    Application.Terminate;
end;

procedure TFrmDreamTeamScore.DoPlayers;
{Load in the list of players from the web}
{look up the details on all the players!
 https://www.dreamteamfc.com/Sun/servlet/PlayerProfile?playerid=4226&gameid=86
}
var
  lType : EPlayerType;
begin
  Label1.Caption := 'Refreshing players...';
  gTeams.Load;
  gPlayers.Load;
  gPersons.Load;

  FEMail.Clear;

  Screen.Cursor := crHourGlass;
  webBrowse.BringToFront;

  {Have to go to this page first!}
  Navigate(mmoStages.Lines[0]);

  for lType := ptGoalKeeper to ptStriker do  begin
    FFilename := gsPlayerType[lType]+'.HTM';
    Navigate(mmoStages.Lines[Ord(lType)+1]);
    FFilename := '';
    UpdatePlayer(lType);
  end;    { for }

  if FEMail.Count>0 then
    EMail('New Players',FEMail.Text,gPersons);

  Screen.Cursor := crDefault;
  Label1.Caption := 'Refreshing players...Done';
end;

procedure TFrmDreamTeamScore.Serve;
begin
  DoPlayers;
  if (Time>StrToTime('17:00:00')) and (Time<StrToTime('18:00:00')) then
    DoAuction;
  DoPoints;
end;

procedure TFrmDreamTeamScore.btnPlayersClick(Sender: TObject);
begin
  DoPlayers;
end;

procedure TFrmDreamTeamScore.btnStopClick(Sender: TObject);
begin
  if assigned(FEvent) then
    FEvent.SetEvent;
end;

procedure TFrmDreamTeamScore.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  btnStop.Click;
end;

procedure TFrmDreamTeamScore.btnServeClick(Sender: TObject);
begin
  Serve;
end;                                                               

end.

