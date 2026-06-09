unit DreamTeam;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Graph,
  StdCtrls, ExtCtrls, Buttons, ComCtrls, Player, Players, Person, Team, Squad, Constants,
  dxDBTLCl, dxGrClms, dxDBCtrl, dxDBGrid, dxTL, Db, dxmdaset, dxCntner, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError,
  Point, PaperTalks;

type
  TFrmDreamTeam = class;

  TPosition = class(TObject)
  private
    FOwner : TFrmDreamTeam;
    FPlayer : TPlayer;
    FSquad : TSquad;
    FButton : TBitBtn;
    FPosition : EPlayerType;
    procedure SetPlayer(const Value: TPlayer);
    procedure SetSquad(const Value : TSquad);
  protected
    procedure Display;
  public
    constructor Create(AOwner : TFrmDreamTeam; ATag : Integer; AButton : TBitBtn; APosition : EPlayerType);

    property Player : TPlayer read FPlayer write SetPlayer;
    property Squad : TSquad read FSquad write SetSquad;
    property Button : TBitBtn read FButton;
    property Position : EPlayerType read FPosition;
  published
  end;

  TFrmDreamTeam = class(TForm)
    pagMain: TPageControl;
    tabSquad: TTabSheet;
    btnNotSelected: TBitBtn;
    btnSelected: TBitBtn;
    tabOverall: TTabSheet;
    dxmOverall: TdxMemData;
    dsOverall: TDataSource;
    dxmOverallPersonID: TIntegerField;
    dxmOverallPersonName: TStringField;
    dxmOverallTeamName: TStringField;
    dxmOverallScore: TIntegerField;
    grdOverall: TdxDBGrid;
    btnArsenal: TBitBtn;
    btnAstonVilla: TBitBtn;
    btnBirmingham: TBitBtn;
    btnBlackburn: TBitBtn;
    btnBolton: TBitBtn;
    btnCharlton: TBitBtn;
    btnChelsea: TBitBtn;
    btnEverton: TBitBtn;
    btnFulham: TBitBtn;
    btnLeeds: TBitBtn;
    btnLiverpool: TBitBtn;
    btnManCity: TBitBtn;
    btnMiddlesbrough: TBitBtn;
    btnManUtd: TBitBtn;
    btnNewcastle: TBitBtn;
    btnSouthampton: TBitBtn;
    btnSunderland: TBitBtn;
    btnTottenham: TBitBtn;
    btnWestBrom: TBitBtn;
    btnWestHam: TBitBtn;
    tabPlayers: TTabSheet;
    btnGoalkeepers: TBitBtn;
    btnDefender: TBitBtn;
    btnMidfielder: TBitBtn;
    btnStriker: TBitBtn;
    btnAll: TBitBtn;
    pnlTop: TPanel;
    btnPrint: TButton;
    btnGraph: TButton;
    Panel1: TPanel;
    dxSquad: TdxDBGrid;
    Panel2: TPanel;
    btnGoalKeeper: TBitBtn;
    btnDefender2: TBitBtn;
    btnDefender1: TBitBtn;
    btnMidfielder1: TBitBtn;
    btnMidfielder2: TBitBtn;
    btnStriker1: TBitBtn;
    btnStriker2: TBitBtn;
    btnStriker3: TBitBtn;
    btnMidfielder3: TBitBtn;
    btnMidfielder4: TBitBtn;
    btnDefender4: TBitBtn;
    btnDefender3: TBitBtn;
    dxmSquad: TdxMemData;
    IntegerField1: TIntegerField;
    StringField1: TStringField;
    StringField2: TStringField;
    FloatField1: TFloatField;
    IntegerField2: TIntegerField;
    IntegerField3: TIntegerField;
    BooleanField1: TBooleanField;
    dsSquad: TDataSource;
    Panel3: TPanel;
    btnAdd: TButton;
    btnRemove: TButton;
    dxmSquadBid: TFloatField;
    dxmSquadSquadID: TStringField;
    Splitter1: TSplitter;
    edtBalance: TEdit;
    Label1: TLabel;
    btn1442: TSpeedButton;
    btn1433: TSpeedButton;
    dxmSquadBidding: TBooleanField;
    btnPortsmouth: TBitBtn;
    btnWigan: TBitBtn;
    dxSquadRecId: TdxDBGridColumn;
    dxSquadSquadID: TdxDBGridMaskColumn;
    dxSquadPlayerID: TdxDBGridMaskColumn;
    dxSquadName: TdxDBGridMaskColumn;
    dxSquadTeam: TdxDBGridMaskColumn;
    dxSquadValue: TdxDBGridMaskColumn;
    dxSquadType: TdxDBGridMaskColumn;
    dxSquadPoints: TdxDBGridMaskColumn;
    dxSquadTransfered: TdxDBGridCheckColumn;
    dxSquadBid: TdxDBGridMaskColumn;
    dxSquadBidding: TdxDBGridCheckColumn;
    grdOverallRecId: TdxDBGridColumn;
    grdOverallPersonID: TdxDBGridMaskColumn;
    grdOverallName: TdxDBGridMaskColumn;
    grdOverallTeam: TdxDBGridMaskColumn;
    grdOverallScore: TdxDBGridMaskColumn;
    tabPoints: TTabSheet;
    dxPoints: TdxDBGrid;
    dsPoints: TDataSource;
    dxmPoints: TdxMemData;
    IntegerField4: TIntegerField;
    StringField3: TStringField;
    StringField4: TStringField;
    IntegerField5: TIntegerField;
    dxmPointsPlayer: TStringField;
    dxPointsRecId: TdxDBGridColumn;
    dxPointsPersonID: TdxDBGridMaskColumn;
    dxPointsName: TdxDBGridMaskColumn;
    dxPointsTeam: TdxDBGridMaskColumn;
    dxPointsPlayer: TdxDBGridMaskColumn;
    dxPointsScore: TdxDBGridMaskColumn;
    dxmPointsDate: TDateField;
    dxPointsDate: TdxDBGridDateColumn;
    TabSheet1: TTabSheet;
    dxDBGrid1: TdxDBGrid;
    PaperTalkMemData: TdxMemData;
    DSPaperTalk: TDataSource;
    PaperTalkMemDataPerson: TStringField;
    PaperTalkMemDataTeam: TStringField;
    PaperTalkMemDataPlayer: TStringField;
    PaperTalkMemDataReason: TStringField;
    PaperTalkMemDataWhen: TDateTimeField;
    PaperTalkMemDataBid: TFloatField;
    dxDBGrid1RecId: TdxDBGridColumn;
    dxDBGrid1Person: TdxDBGridMaskColumn;
    dxDBGrid1Team: TdxDBGridMaskColumn;
    dxDBGrid1When: TdxDBGridDateColumn;
    dxDBGrid1Player: TdxDBGridMaskColumn;
    dxDBGrid1Reason: TdxDBGridMaskColumn;
    dxDBGrid1Bid: TdxDBGridMaskColumn;
    PaperTalkMemDatarowid: TStringField;
    procedure btnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tabScoreShow(Sender: TObject);
    procedure tabScoreHide(Sender: TObject);
    procedure zzzzdxmScorePlayerTypeGetText(Sender: TField; var Text: String;
      DisplayText: Boolean);
    procedure tabOverallShow(Sender: TObject);
    procedure tabOverallHide(Sender: TObject);
    procedure btnGoalkeepersClick(Sender: TObject);
    procedure btnDefenderClick(Sender: TObject);
    procedure btnMidfielderClick(Sender: TObject);
    procedure btnStrikerClick(Sender: TObject);
    procedure btnAllClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure btnGraphClick(Sender: TObject);
    procedure btnBidClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dxSquadStartDrag(Sender: TObject;
      var DragObject: TDragObject);
    procedure btnDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure btnDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btn1442Click(Sender: TObject);
    procedure btn1433Click(Sender: TObject);
    procedure dxSquadEndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure tabPointsShow(Sender: TObject);
    procedure tabPointsHide(Sender: TObject);
  private
    { Private declarations }
    FButtons : Array[0..11] of TPosition;
    FBids : Array[0..11] of TPosition;
    FPersonID : Integer;
    FSelect : TFrmPlayers;
    FDrag : TSquad;
    function GetPerson : TPerson;
    procedure ToDisplay;
    procedure DoOnValidate(ASender : TObject; APlayer : TPlayer; var OK : Boolean);
  public
    { Public declarations }
    property Person : TPerson read GetPerson;
    property PersonID : Integer read FPersonID write FPersonID;
    property Select : TFrmPlayers read FSelect;
  end;

var
  FrmDreamTeam: TFrmDreamTeam;

implementation

uses DreamTeamMain, Database;

{$R *.DFM}

function TFrmDreamTeam.GetPerson : TPerson;
begin
  result := gPersons.Find(FPersonID);
end;

procedure TFrmDreamTeam.ToDisplay;
var
  C : Integer;
  lSquad : TSquad;
  LPaperTalkItem : TPaperTalkItem;
  D : Integer;
  Mid,
  Str : Integer;
begin
  gTeams.Load;
  gPlayers.Load;
  gPersons.Load;

  edtBalance.Text := Format('£%6.2f',[cTotalPrice-Person.Price]);
  
  for D := 0 to Length(FButtons)-1 do { Iterate } begin
    FButtons[D].Player := Nil;
    FButtons[D].Squad := Nil;
  end;

  Mid := 0;
  Str := 0;
  for C := 0 to Person.Squads.Count-1 do { Iterate } begin
    lSquad := Person.Squads[C] as TSquad;
    if not lSquad.Playing then
      Continue;
//    if lSquad.UntilAt<Now then
//      Continue;
//    if lSquad.Valid then begin
    if lSquad.Player.PlayerType=ptMidfielder then begin
      Inc(Mid);
//      if Mid>3 then
//        btnStriker3.Enabled := False
//      else
//        btnStriker3.Enabled := True;
    end;
    if lSquad.Player.PlayerType=ptStriker then begin
      Inc(Str);
//      if Str>2 then
//        btnMidfielder4.Enabled := False
//      else
//        btnMidfielder4.Enabled := True;
    end;

    for D := 0 to Length(FButtons)-1 do { Iterate } begin
      if (not assigned(FButtons[D].Player)) and (FButtons[D].Position=lSquad.Player.PlayerType) then begin
        FButtons[D].Player := lSquad.Player;
        FButtons[D].Squad := lSquad;
        break;
      end;
    end;    { for }
//  end;
  end;    { for }

  if Mid>3 then begin
    btn1442.Down := True;
    btn1442.Click;
  end;
  if Str>2 then begin
    btn1433.Down := True;
    btn1433.Click;
  end;

  dxmSquad.Open;
  while not dxmSquad.Eof do begin
    dxmSquad.Delete;
  end;    { while }
  for C := 0 to Person.Squads.Count-1 do { Iterate } begin
    lSquad := Person.Squads[C] as TSquad;
    dxmSquad.Append;
    dxmSquad.FieldByName('SQUADID').AsInteger := lSquad.SquadID;
    dxmSquad.FieldByName('PLAYERID').AsInteger := lSquad.Player.PlayerID;
    dxmSquad.FieldByName('NAME').AsString := lSquad.Player.Name;
    dxmSquad.FieldByName('TEAM').AsString := lSquad.Player.Team.Name;
    dxmSquad.FieldByName('VALUE').AsFloat := lSquad.Player.Price;
    dxmSquad.FieldByName('TYPE').AsInteger := Ord(lSquad.Player.PlayerType);
    dxmSquad.FieldByName('TRANSFERED').AsBoolean := lSquad.UntilAt<Now;
    dxmSquad.FieldByName('BID').AsFloat := lSquad.Bid;
    dxmSquad.FieldByName('BIDDING').AsBoolean := not lSquad.Valid;
    dxmSquad.FieldByName('POINTS').AsInteger := lSquad.Player.Points;
    dxmSquad.Post;
  end;    { for }

  PaperTalkMemData.Open;
  while not PaperTalkMemData.Eof do begin
    PaperTalkMemData.Delete;
  end;    { while }
  for C := 0 to  gPaperTalk.PaperTalkItems.Count-1 do { Iterate } begin
    LPaperTalkItem := gPaperTalk.PaperTalkItems.Items[C] as TPaperTalkItem;
    PaperTalkMemData.Append;
    PaperTalkMemData.FieldByName('ROWID').AsString := LPaperTalkItem.Person;
    PaperTalkMemData.FieldByName('PERSON').AsString := LPaperTalkItem.Person;
    PaperTalkMemData.FieldByName('TEAM').AsString := LPaperTalkItem.Team;
    PaperTalkMemData.FieldByName('PLAYER').AsString := LPaperTalkItem.Player;
    PaperTalkMemData.FieldByName('REASON').AsString := LPaperTalkItem.Text;
    PaperTalkMemData.FieldByName('WHEN').AsDateTime := LPaperTalkItem.Date;
    PaperTalkMemData.FieldByName('BID').AsFloat := LPaperTalkItem.Bid;

    PaperTalkMemData.Post;
  end;    { for }


end;

procedure TFrmDreamTeam.DoOnValidate(ASender : TObject; APlayer : TPlayer; var OK : Boolean);
var
  C : Integer;
  lSquad : TSquad;
begin
  OK := True;
  {Need to ensure, same player not added twice}
  for C := 0 to Person.Squads.Count-1 do { Iterate } begin
    lSquad := Person.Squads[C] as TSquad;
    if (lSquad.Player.PlayerID=APlayer.PlayerID) or (APlayer.Used) then begin
      OK := False;
      break;
    end;
    lSquad := Nil;
  end;    { for }
  OK := OK and (not APlayer.Used);
end;

procedure TFrmDreamTeam.btnClick(Sender: TObject);
var
  Btn : TBitBtn;
  Idx : Integer;
  C : Integer;
  OK : Boolean;
  lSquad : TSquad;
  Players : Array[EPlayerType] of Integer;
  Bids : Array[EPlayerType] of Integer;
  _4,_3 : Integer;
begin
//  FrmDreamTeamScore.TimeWarp;

  Btn := Sender as TBitBtn;
  Idx := Btn.Tag;

//  if FButtons[Idx].Squad.ReplaceID>0 then
//    exit;
//  if assigned(FButtons[Idx].Squad) then
//    if FButtons[Idx].Squad.UntilAt<Now+5 then
//      {Replacement already chosen, to change this alter the bid!}
//      exit;

  {Count players n bids and ensure we can get someone else!}
//  FillChar(Players,SizeOf(Players),0);
//  FillChar(Bids,SizeOf(Bids),0);
//  for C := 0 to FPerson.Squad.Count-1 do begin
//    lSquad := FPerson.Squad[C] as TSquad;
//    if lSquad.Valid then begin
//      {Player is or was in squad}
//      if (lSquad.UntilAt>Now) then
//        {Still in squad}
//        Inc(Players[lSquad.Player.PlayerType]);
//    end else begin
//      {Player bid on!}
//      Inc(Bids[lSquad.Player.PlayerType]);
//    end;
//  end;
//  {1-4-4-2 or 1-4-3-3 formation!}
//  OK := False;
//  if Players[ptStriker]=3 then begin
//    _4 := 3;
//    _3 := 2;
//  end else begin
//    _4 := 4;
//    _3 := 3;
//  end;
//  if assigned(FButtons[Idx].Player) then begin
//      {Replacing someone!}
//      case FButtons[Idx].Position of
//        ptGoalKeeper : OK := ((Players[ptGoalKeeper]+Bids[ptGoalKeeper])<=1); {Spare slot}
//        ptDefender   : OK := ((Players[ptDefender]+Bids[ptDefender])<=4); {Spare slot}
////        ptMidFielder : OK := ((Players[ptMidfielder]+Bids[ptMidfielder])<=_4); {Spare slot}
//        ptMidFielder : OK := ((Players[ptMidfielder])<=(_4-Bids[ptMidfielder])); {Spare slot}
//        ptStriker : OK := ((Players[ptStriker]+Bids[ptStriker])<=_3); {Spare slot}
//      end;
//  end else begin
//    {Adding someone new}
//    case FButtons[Idx].Position of
//      ptGoalKeeper : OK := ((Players[ptGoalKeeper]+Bids[ptGoalKeeper])<1); {Spare slot}
//      ptDefender   : OK := ((Players[ptDefender]+Bids[ptDefender])<4); {Spare slot}
////      ptMidFielder : OK := ((Players[ptMidfielder]+Bids[ptMidfielder])<_4); {Spare slot}
//      ptMidFielder : OK := ((Players[ptMidfielder])<(_4-Bids[ptMidfielder])); {Spare slot}
//      ptStriker : OK := ((Players[ptStriker]+Bids[ptStriker])<_3); {Spare slot}
//    end;
//  end;  
//
//  if not OK then
//    exit;

//  FSelect.PlayerSet := [FButtons[Idx].Position];
//  FSelect.Review := False;
//  FSelect.MaxPrice := cTotalPrice-FPerson.Price;
//  if assigned(FButtons[Idx].Player) then begin
//    if FButtons[Idx].Squad.Valid then
//      FSelect.MaxPrice := FSelect.MaxPrice + FButtons[Idx].Player.Price
//    else
//      FSelect.MaxPrice := FSelect.MaxPrice + FButtons[Idx].Squad.Bid
//  end;
//  case FSelect.ShowModal of
//    mrOK : FPerson.Replace(FButtons[Idx].Player,FSelect.Player,FSelect.Bid);
//    mrCancel : ;
//  end;
  FDrag.Playing := True;
  if assigned(FButtons[Idx].Squad) then begin
    FButtons[Idx].Squad.Playing := False;
    FButtons[Idx].Squad.Save;
  end;
  FButtons[Idx].Squad := FDrag;
  FButtons[Idx].Squad.Save;
  FDrag := Nil;
  ToDisplay;
end;

procedure TFrmDreamTeam.FormCreate(Sender: TObject);
begin
  FSelect := TFrmPlayers.Create(Self);
  
  FButtons[0] := TPosition.Create(Self, 0, btnGoalKeeper,ptGoalKeeper);

  FButtons[1] := TPosition.Create(Self, 1, btnDefender1,ptDefender);
  FButtons[2] := TPosition.Create(Self, 2, btnDefender2,ptDefender);
  FButtons[3] := TPosition.Create(Self, 3, btnDefender3,ptDefender);
  FButtons[4] := TPosition.Create(Self, 4, btnDefender4,ptDefender);

  FButtons[5] := TPosition.Create(Self, 5, btnMidFielder1,ptMidfielder);
  FButtons[6] := TPosition.Create(Self, 6, btnMidFielder2,ptMidfielder);
  FButtons[7] := TPosition.Create(Self, 7, btnMidFielder3,ptMidfielder);
  FButtons[8] := TPosition.Create(Self, 8, btnMidFielder4,ptMidfielder);

  FButtons[9] := TPosition.Create(Self, 9, btnStriker1,ptStriker);
  FButtons[10] := TPosition.Create(Self, 10, btnStriker2,ptStriker);
  FButtons[11] := TPosition.Create(Self, 11, btnStriker3,ptStriker);

  gPaperTalk := TPaperTalk.Create;
  gPaperTalk.LoadItems;
end;

{ TPosition }

constructor TPosition.Create(AOwner : TFrmDreamTeam; ATag : Integer; AButton : TBitBtn; APosition : EPlayerType);
begin
  inherited Create;
  FOwner := AOwner;
  FButton := AButton;
  FPosition := APosition;
  FButton.Tag := ATag;
end;

procedure TPosition.Display;
var
  C : Integer;
  Cmp : TComponent;
  Btn : TBitBtn;
begin
  if assigned(FPlayer) and assigned(FSquad) then begin
    FButton.Glyph := FOwner.btnSelected.Glyph;
    FButton.NumGlyphs := 1;
    for C := 0 to FOwner.tabSquad.ControlCount-1 do { Iterate } begin
      Cmp := FOwner.tabSquad.Controls[C];
      if Cmp is TBitBtn then begin
        Btn := Cmp as TBitBtn;
        if Btn.Caption=FPlayer.Team.Name then begin
          FButton.Glyph := btn.Glyph;
          FButton.NumGlyphs := 1;
          break;
        end;
      end;
    end;    { for }
    if FSquad.Valid then
      FButton.Font.Color := clWindowText
    else
      FButton.Font.Color := clRed;
//    if FrmDreamTeam.chkBids.Checked then
    FButton.Caption := FPlayer.Name+#13#10+FPlayer.Team.Name+#13#10+Format('£%4.1f £%4.1f',[FPlayer.Price,FSquad.Bid])
//    else
//      FButton.Caption := FPlayer.Name+#13#10+FPlayer.Team+#13#10+Format('£%4.1f',[FPlayer.Price]);
  end else begin
    FButton.Glyph := FOwner.btnNotSelected.Glyph;
    FButton.NumGlyphs := 1;
    FButton.Caption := gsPlayerType[FPosition];
  end;
end;

procedure TPosition.SetPlayer(const Value: TPlayer);
begin
  FPlayer := Value;
  Display;
end;

procedure TPosition.SetSquad(const Value : TSquad);
begin
  FSquad := Value;
  Display;
end;

procedure TFrmDreamTeam.tabScoreShow(Sender: TObject);
//var
//  C : Integer;
//  lSquad : TSquad;
//  Qry : TOraQuery;
begin
//  {Load up the users score information}
//  dxmScore.Open;
//  while not dxmScore.Eof do begin
//    dxmScore.Delete;
//  end;    { while }
////  for C := 0 to FPerson.Squad.Count-1 do { Iterate } begin
////    lSquad := FPerson.Squad[C] as TSquad;
////    dxmScore.Append;
////    dxmScore.FieldByName('PLAYERID').AsInteger := lSquad.Player.PlayerID;
////    dxmScore.FieldByName('PLAYERNAME').AsString := lSquad.Player.Name;
////    dxmScore.FieldByName('PLAYERTEAM').AsString := lSquad.Player.Team;
////    dxmScore.FieldByName('PLAYERVALUE').AsFloat := lSquad.Player.Price;
////    dxmScore.FieldByName('PLAYERTYPE').AsInteger := Ord(lSquad.Player.PlayerType);
////{$IFDEF Paradox}    
////    dxmScore.FieldByName('PLAYERTRANSFERED').AsBoolean := lSquad.UntilAt<Now;
////{$ELSE}
////    dxmScore.FieldByName('PLAYERTRANSFERED').AsBoolean := lSquad.UntilAt<Now;
////{$ENDIF}    
////    dxmScore.Post;
////  end;    { for }
//
//  Qry := TOraQuery.Create(Self);
//  Qry.SessionName := sesDream;
//  Qry.DatabaseName := dbDream;
//  with Qry,SQL do begin
//{ For some reason this doesn't work
//    Add('select');
//    Add('sum(delta) as points, p.playerid');
//    Add('from');
//    Add('points p, squad s, team t, person e');
//    Add('where');
//    Add('t.teamid=s.teamid and');
//    Add('e.personid=t.personid and');
//    Add('p.playerid=s.playerid and');
//    Add('((s.fromat<=p.untilat and s.untilat>=p.untilat) or');
//    Add(' (p.fromat<=p.fromat and p.untilat>=s.untilat))');
//    Add('and T.TEAMID=:TEAMID');
//    Add('group by p.playerid');
//
//    Add('select * from points p, squad s, team t where t.teamid=:teamid');
//    Add('and p.playerid');
//    Add('order by untilat');
//
//Before
//    Add('select');
//    Add('sum(delta) as points, p.playerid');
//    Add('from');
//    Add('points p, squad s');
//    Add('where');
//    Add('p.playerid=s.playerid and');
//    Add('((s.fromat<=p.untilat and s.untilat>=p.untilat) or');
//    Add(' (p.fromat<=p.fromat and p.untilat>=s.untilat))');
//    Add('and s.TEAMID=:TEAMID');
//    Add('group by p.playerid');
//}
//    Add('select');
//    Add('sum(delta) as points, p.playerid');
//    Add('from');
//    Add('points p, squad s');
//    Add('where');
//    Add('p.playerid=s.playerid and');
//    Add('s.PERSONID=:PERSONID and');
//    Add('((p.fromat>=s.fromat) and (p.untilat<=s.untilat))');
//    Add('group by p.playerid');
//
//    ParamByName('PERSONID').AsInteger := Person.ID;
//    Open;
//    while not Eof do begin
//      if dxmScore.Locate('PLAYERID',FieldByName('PLAYERID').AsInteger,[]) then begin
////        ShowMessage('Its broken!');
//        dxmScore.Edit;
//        dxmScore.FieldByName('PLAYERPOINTS').AsInteger := FieldByName('POINTS').AsInteger;
//        dxmScore.Post;
//      end;
//      Next;
//    end;    { while }
//    Close;
//  end;    { with }
//  Qry.Free;
end;

procedure TFrmDreamTeam.tabScoreHide(Sender: TObject);
begin
//  dxmScore.Close;
end;

procedure TFrmDreamTeam.zzzzdxmScorePlayerTypeGetText(Sender: TField;
  var Text: String; DisplayText: Boolean);
begin
  Text := gsPlayerType[EPlayerType(Sender.AsInteger)];
end;

procedure TFrmDreamTeam.tabOverallShow(Sender: TObject);
var
  Person : TPerson;
  Qry : TOraQuery;
begin
  dxmOverall.Open;
  while not dxmOverall.Eof do begin
    dxmOverall.Delete;
  end;    { while }

  Qry := TOraQuery.Create(Self);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('select');
    Add('s.personid, sum(o.points) as points');
    Add('from');
    Add('playing p, points o, squad s');
    Add('where');
    Add('s.squadid=p.squadid and');
    Add('p.playerid=o.playerid and');
    Add('o.fromat+0.99998843 between p.fromat and nvl(p.untilat, to_date(''01-JAN-9999''))');
    Add('group by s.personid');
    Open;
    while not Eof do begin
      Person := gPersons.Find(Qry.FieldByName('PERSONID').AsInteger);
      dxmOverall.Append;
      dxmOverall.FieldByName('PERSONID').AsInteger := Person.ID;
      dxmOverall.FieldByName('SCORE').AsInteger := Qry.FieldByName('POINTS').AsInteger;
      dxmOverall.FieldByName('NAME').AsString := Person.UserName;
      dxmOverall.FieldByName('TEAM').AsString := Person.Team;
      dxmOverall.Post;
      Person := Nil;
      
      Next;
    end;    { while }
    Close;
  end;    { with }
end;

procedure TFrmDreamTeam.tabOverallHide(Sender: TObject);
begin
  dxmOverall.Close;
end;

procedure TFrmDreamTeam.btnGoalkeepersClick(Sender: TObject);
begin
  FSelect.PlayerSet := [ptGoalKeeper];
  FSelect.Review := True;
  FSelect.ShowModal;
end;

procedure TFrmDreamTeam.btnDefenderClick(Sender: TObject);
begin
  FSelect.PlayerSet := [ptDefender];
  FSelect.Review := True;
  FSelect.ShowModal;
end;

procedure TFrmDreamTeam.btnMidfielderClick(Sender: TObject);
begin
  FSelect.PlayerSet := [ptMidfielder];
  FSelect.Review := True;
  FSelect.ShowModal;
end;

procedure TFrmDreamTeam.btnStrikerClick(Sender: TObject);
begin
  FSelect.PlayerSet := [ptStriker];
  FSelect.Review := True;
  FSelect.ShowModal;
end;

procedure TFrmDreamTeam.btnAllClick(Sender: TObject);
begin
  FSelect.PlayerSet := [ptGoalKeeper,ptDefender,ptMidfielder,ptStriker];
  FSelect.Review := True;
  FSelect.ShowModal;
end;

procedure TFrmDreamTeam.btnPrintClick(Sender: TObject);
begin
  Self.Print;
end;

procedure TFrmDreamTeam.btnGraphClick(Sender: TObject);
var
  Frm : TFrmGraph;
begin
  Frm := TFrmGraph.Create(Self);
  Frm.Show;
end;

procedure TFrmDreamTeam.btnBidClick(Sender: TObject);
var
  Btn : TBitBtn;
  Idx : Integer;
  lBid : Extended;
  C : Integer;
  oSquad,
  lSquad : TSquad;
begin
  {Change/Cancel a bid!}
  FrmDreamTeamScore.TimeWarp;
//
//  Btn := Sender as TBitBtn;
//  Idx := Btn.Tag;
//
//  if not assigned(FBids[Idx].Squad) then
//    exit;
//
//  try  
//    lBid := StrToFloat(edtBid.Text);
//  except
//  end;
//  case MessageDlg('Change bid? Yes=Change, No=Delete',mtConfirmation,[mbYes,mbNo,mbCancel],0) of
//    mrYes    : 
//      begin
//        if lBid>FBids[Idx].Player.Price then begin
//          FBids[Idx].Squad.Bid := lBid;
//          FBids[Idx].Squad.Save;
//        end;
//      end;
//    mrNo     : 
//      begin
//        {Find who we replaced and put em back}
//        oSquad := FBids[Idx].Squad;
////        for C := 0 to FPerson.Squad.Count-1 do begin
////          lSquad := FPerson.Squad[C] as TSquad;
////          if lSquad.Valid then begin
////            if lSquad.PlayerID=oSquad.ReplaceID then begin
////              lSquad.UntilAt := cForever;
////              lSquad.ReplaceID := -1;
////              lSquad.Save;
////            end;
////          end;
////        end;
////        oSquad.Delete;
////        for C := 0 to FPerson.Squad.Count-1 do begin
////          if oSquad=FPerson.Squad[C] as TSquad then begin
////            FPerson.Squad.Delete(C);
////            break;
////          end;
////        end;
////        FBids[Idx].Squad := Nil;
////        FBids[Idx].Player := Nil;
//      end;
//    mrCancel : exit;  
//  end;
//  ToDisplay;
end;

procedure TFrmDreamTeam.btnRemoveClick(Sender: TObject);
var
  C : Integer;
  lNode : TdxTreeListNode;
  lSquad : TSquad;
begin
  case MessageDlg('Are you absolutely positive you wish to do this! No second chances!',mtConfirmation,[mbYes,mbNo],0) of
    mrYes :
      begin
        for C := 0 to dxSquad.SelectedCount-1 do begin
          lNode := dxSquad.SelectedNodes[C];
          lSquad := Person.Squads.Find(lNode.Values[1]);

          if lSquad.UntilAt>Now+1 then begin

            lSquad.UntilAt := Now;
            lSquad.Bid := lSquad.Bid - lSquad.Player.Price; {Only get back a portion of what you paid for em!}
            lSquad.Save;
            lSquad.Player.Used := False;
            lSquad.Player.Save;
          end;
          lSquad := Nil;
        end;
        lNode := dxSquad.FocusedNode;
        if assigned(lNode) then begin
          lSquad := Person.Squads.Find(lNode.Values[1]);
          if lSquad.Valid then begin
            if lSquad.UntilAt>Now+1 then begin
              gPaperTalk.InsertItem('-', '-', lSquad.Player.Name, now, 'Put on transfer list', lSquad.Player.Price);
              lSquad.UntilAt := Now;
              lSquad.Bid := lSquad.Bid - lSquad.Player.Price; {Only get back a portion of what you paid for em!}
              lSquad.Save;
            end;
          end else
            lSquad.Delete;
          lSquad.Player.Used := False;
          lSquad.Player.Save;
          lSquad := Nil;
        end;
        ToDisplay;
      end;
  end;
end;

procedure TFrmDreamTeam.btnAddClick(Sender: TObject);
var
  lSquad : TSquad;
begin
  FSelect.Review := False;
  FSelect.PlayerSet := [ptGoalKeeper,ptDefender,ptMidfielder,ptStriker];
  FSelect.MaxPrice := cTotalPrice-Person.Price;
  FSelect.OnValidate := DoOnValidate;
  case FSelect.ShowModal of
    mrOK :
      begin
        lSquad := TSquad.Create(Person.ID,-1,FSelect.Player.PlayerID,Now,cForever,FSelect.Bid,False);
        Person.Squads.Add(lSquad);
      end;
    mrCancel : ;
  end;
  ToDisplay;
end;

procedure TFrmDreamTeam.FormShow(Sender: TObject);
begin
  ToDisplay;
end;

procedure TFrmDreamTeam.dxSquadStartDrag(Sender: TObject;
  var DragObject: TDragObject);
begin
  {}
  FDrag := Person.Squads.Find(dxSquad.FocusedNode.Values[1]);
  if FDrag.UntilAt<Now then
    FDrag := Nil;
  if assigned(FDrag) then
    dxSquad.Enabled := False;
end;

procedure TFrmDreamTeam.btnDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  Btn : TBitBtn;
  Idx : Integer;
begin
  {}
  Btn := Sender as TBitBtn;
  Idx := Btn.Tag;
//  if assigned(FButtons[Idx].Squad) then
  if Assigned(FDrag) then
    Accept := FDrag.Player.PlayerType=FButtons[Idx].Position
  else
    Accept := False;
end;

procedure TFrmDreamTeam.btnDragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
  {}
  TBitBtn(Sender).Click;
end;

procedure TFrmDreamTeam.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TFrmDreamTeam.btn1442Click(Sender: TObject);
begin
  btnStriker3.Enabled := False;
  btnMidfielder4.Enabled := True;
  if assigned(FButtons[btnStriker3.Tag].Squad) then begin
    FButtons[btnStriker3.Tag].Squad.Playing := False;
    FButtons[btnStriker3.Tag].Squad.Save;
    ToDisplay;
  end;
  FButtons[btnStriker3.Tag].Squad := Nil;
end;

procedure TFrmDreamTeam.btn1433Click(Sender: TObject);
begin
  btnStriker3.Enabled := True;
  btnMidfielder4.Enabled := False;
  if assigned(FButtons[btnMidfielder4.Tag].Squad) then begin
    FButtons[btnMidfielder4.Tag].Squad.Playing := False;
    FButtons[btnMidfielder4.Tag].Squad.Save;
    ToDisplay;
  end;
  FButtons[btnMidfielder4.Tag].Squad := Nil;
end;

procedure TFrmDreamTeam.dxSquadEndDrag(Sender, Target: TObject; X,
  Y: Integer);
begin
  dxSquad.Enabled := True;
end;

procedure TFrmDreamTeam.tabPointsShow(Sender: TObject);
var
  Person : TPerson;
  Player : TPlayer;
  Qry : TOraQuery;
begin
  dxmPoints.Open;
  while not dxmPoints.Eof do begin
    dxmPoints.Delete;
  end;    { while }

  Qry := TOraQuery.Create(Self);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('select');
    Add('s.personid, p.playerid, o.fromat, sum(o.points) as points');
    Add('from');
    Add('playing p, points o, squad s');
    Add('where');
    Add('s.squadid=p.squadid and');
    Add('p.playerid=o.playerid and');
    Add('o.fromat+0.99998843 between p.fromat and nvl(p.untilat, to_date(''01-JAN-9999''))');
    Add('group by s.personid, p.playerid, o.fromat');
    Open;
    while not Eof do begin
      Person := gPersons.Find(Qry.FieldByName('PERSONID').AsInteger);
      dxmPoints.Append;
      dxmPoints.FieldByName('PERSONID').AsInteger := Person.ID;
      dxmPoints.FieldByName('SCORE').AsInteger := Qry.FieldByName('POINTS').AsInteger;
      dxmPoints.FieldByName('NAME').AsString := Person.UserName;
      PLayer := gPlayers.Find(Qry.FieldByName('PLAYERID').AsInteger);
      dxmPoints.FieldByName('PLAYER').AsString := Player.Team.Name+':'+PLayer.Name;
      dxmPoints.FieldByName('DATE').AsDateTime := Qry.FieldByName('FROMAT').AsDateTime;
      dxmPoints.FieldByName('TEAM').AsString := Person.Team;
      dxmPoints.Post;
      Person := Nil;

      Next;
    end;    { while }
    Close;
  end;    { with }
end;

procedure TFrmDreamTeam.tabPointsHide(Sender: TObject);
begin
  dxmPoints.Close;
end;

end.
