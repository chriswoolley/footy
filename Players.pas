unit Players;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, StdCtrls, ExtCtrls, dxmdaset, dxCntner, dxTL, dxDBCtrl, dxDBGrid, PLayer,
  Constants, Person,
  Team, Squad, dxDBTLCl, dxGrClms;

type
  TOnValidate = procedure(ASender : TObject; APlayer : TPlayer; var OK : boolean) of object;
  
type
  TFrmPlayers = class(TForm)
    grdPlayers: TdxDBGrid;
    dxmPlayers: TdxMemData;
    dsPlayers: TDataSource;
    pnlButton: TPanel;
    btnSelect: TButton;
    btnCancel: TButton;
    dxmPlayersPlayerID: TIntegerField;
    dxmPlayersPlayerName: TStringField;
    dxmPlayersPlayerTeam: TStringField;
    dxmPlayersPlayerValue: TFloatField;
    dxmPlayersPlayerPoints: TIntegerField;
    dxmPlayersRatioPoundsPerPoint: TFloatField;
    dxmPlayersRatioPointsPerPound: TFloatField;
    lblBid: TLabel;
    edtBid: TEdit;
    dxmPlayersType: TStringField;
    edtMax: TEdit;
    Label1: TLabel;
    btnExport: TButton;
    dlgSave: TSaveDialog;
    dxmPlayersUsed: TBooleanField;
    grdPlayersRecId: TdxDBGridColumn;
    grdPlayersPlayerID: TdxDBGridMaskColumn;
    grdPlayersName: TdxDBGridMaskColumn;
    grdPlayersTeam: TdxDBGridMaskColumn;
    grdPlayersValue: TdxDBGridMaskColumn;
    grdPlayersPoints: TdxDBGridMaskColumn;
    grdPlayersRatioPoundsPerPoint: TdxDBGridColumn;
    grdPlayersRatioPointsPerPound: TdxDBGridColumn;
    grdPlayersType: TdxDBGridMaskColumn;
    grdPlayersUsed: TdxDBGridCheckColumn;
    procedure btnCancelClick(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure grdPlayersCustomDrawCell(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; ANode: TdxTreeListNode; AColumn: TdxTreeListColumn;
      ASelected, AFocused, ANewItemRow: Boolean; var AText: String;
      var AColor: TColor; AFont: TFont; var AAlignment: TAlignment;
      var ADone: Boolean);
    procedure grdPlayersDblClick(Sender: TObject);
    procedure btnNobodyClick(Sender: TObject);
    procedure dxmPlayersCalcFields(DataSet: TDataSet);
    procedure btnExportClick(Sender: TObject);
  private
    { Private declarations }
    FPerson : TPerson;
    FPlayer: TPlayer;
    FPlayerSet: SPlayerType;
    FMaxPrice: Extended;
    FBid : Extended;
    FOnValidate: TOnValidate;
    FReview : Boolean;
  public
    { Public declarations }
    property Person : TPerson read FPerson write FPerson;
    property Player : TPlayer read FPlayer;
    property PlayerSet : SPlayerType read FPlayerSet write FPlayerSet;
    property MaxPrice : Extended read FMaxPrice write FMaxPrice;
    property Bid : Extended read FBid write FBid;
    property OnValidate : TOnValidate read FOnValidate write FOnValidate;
    property Review : Boolean read FReview write FReview;
  end;

var
  FrmPlayers: TFrmPlayers;

implementation

{$R *.DFM}

{ TFrmPlayers }

procedure TFrmPlayers.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmPlayers.btnSelectClick(Sender: TObject);
var
  OK : Boolean;
begin
  Modalresult := mrNone;
  FPlayer := gPlayers.Find(dxmPlayers.FieldByName('PLAYERID').AsInteger);
  FBid := StrToFloat(edtBid.Text);
  if FBid<FPlayer.Price then
    exit;

  if (FPlayer.Price<=FMaxPrice) and (FBid-0.00000000000001<=FMaxPrice) then begin
    Ok := True;
    if assigned(FOnValidate) then
      FOnValidate(Self,FPlayer,OK);
    if OK then
      ModalResult := mrOK
    else
      ModalResult := mrNone;
  end;
end;

procedure TFrmPlayers.FormShow(Sender: TObject);
var
  C : Integer;
begin
  dxmPlayers.Open;
  while not dxmPlayers.Eof do begin
    dxmPlayers.Delete;
  end;    { while }
  for C := 0 to gPlayers.Count-1 do { Iterate } begin
    if gPlayers[C].PlayerType in FPlayerSet then begin
      dxmPlayers.Append;
      dxmPlayers.FieldByName('PLAYERID').AsInteger := gPlayers[C].PlayerID;
      dxmPlayers.FieldByName('TYPE').AsString := gsPlayerType[gPlayers[C].PlayerType];
      dxmPlayers.FieldByName('NAME').AsString := gPlayers[C].Name;
      dxmPlayers.FieldByName('TEAM').AsString := gPlayers[C].Team.Name;
      dxmPlayers.FieldByName('VALUE').AsFloat := gPlayers[C].Price;
      dxmPlayers.FieldByName('POINTS').AsInteger := gPlayers[C].Points;
      dxmPlayers.FieldByName('USED').AsBoolean := gPlayers[C].Used;
      dxmPlayers.Post;
    end;
  end;    { for }
  btnSelect.Enabled := not FReview;
  if FReview then
    FMaxPrice := cTotalPrice;
  edtMax.Text := Format('£%6.2f',[FMaxPrice]);
end;

procedure TFrmPlayers.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  dxmPlayers.Close;
end;

procedure TFrmPlayers.grdPlayersCustomDrawCell(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; ANode: TdxTreeListNode;
  AColumn: TdxTreeListColumn; ASelected, AFocused, ANewItemRow: Boolean;
  var AText: String; var AColor: TColor; AFont: TFont;
  var AAlignment: TAlignment; var ADone: Boolean);
var
  OK : Boolean;
  lPlayer : TPlayer;
begin
  OK := True;
  if ANode.HasChildren then
    exit;
  lPlayer := gPlayers.Find(ANode.Values[1]);
  if assigned(FOnValidate) then begin
    FOnValidate(Self,lPlayer,OK);
    OK := OK or (FReview);
    OK := OK {and (not lPlayer.InTeam)};
    if ASelected then begin
      if not OK then begin
        AColor := grdPlayers.HighlightColor;
        AFont.Color := clYellow;
      end else if (ANode.Values[4]>MaxPrice) then begin
        AColor := grdPlayers.HighlightColor;
        AFont.Color := clYellow;
      end else begin
        AColor := clWhite;
        AFont.Color := grdPlayers.Font.Color;
      end;
    end else if AFocused then begin
      if not OK then begin
        AColor := clWhite;
        AFont.Color := clBlue;
      end else if (ANode.Values[4]>MaxPrice) then begin
        AColor := clWhite;
        AFont.Color := clRed;
      end else begin
        AColor := clWhite;
        AFont.Color := grdPlayers.Font.Color;
      end;
    end else begin
      if not OK then begin
        AColor := clBlue;
        AFont.Color := grdPlayers.HighlightTextColor;
      end else if (ANode.Values[4]>MaxPrice) then begin
        AColor := clRed;
        AFont.Color := grdPlayers.HighlightTextColor;
      end else begin
        AColor := clWhite;
        AFont.Color := grdPlayers.Font.Color;
      end;
    end;
  end;
end;

procedure TFrmPlayers.grdPlayersDblClick(Sender: TObject);
begin
  btnSelect.Click;
end;

procedure TFrmPlayers.btnNobodyClick(Sender: TObject);
begin
  FPlayer := Nil;
  ModalResult := mrOK;
end;

procedure TFrmPlayers.dxmPlayersCalcFields(DataSet: TDataSet);
var
  Val : Extended;
  Poi : Extended;
begin
  with DataSet do begin
    Val := FieldByName('Value').AsFloat;
    Poi := FieldByName('Points').AsFloat;
    if Val>0 then
      FieldByName('RatioPointsPerPound').AsFloat := Poi/Val
    else
      FieldByName('RatioPointsPerPound').AsFloat := 0;
    if Poi<>0 then
      FieldByName('RatioPoundsPerPoint').AsFloat := Val/Poi
    else
      FieldByName('RatioPoundsPerPoint').AsFloat := 0;
  end;    { with }
end;

procedure TFrmPlayers.btnExportClick(Sender: TObject);
begin
  if dlgSave.Execute then
    grdPlayers.SaveToXLS(dlgSave.FileName,True);
end;

end.
