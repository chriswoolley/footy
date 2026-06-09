unit PaperTalks;

interface

uses
  Windows, Classes, SysUtils, Contnrs, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Utilities, Constants, Database;

type
  TPaperTalkItem = class(TObject)
  private
    FRowID : string;
    FPerson : string;
    FTeam : string;
    FPlayer : string;
    FDate : TDateTime;
    FText : String;
    FBid : Extended; {Millions}
  protected
  public
  published
    property Person : string read FPerson write FPerson;
    property Team : string read FTeam write FTeam;
    property Player : string read FPlayer write FPlayer;
    property Date : TDateTime read FDate write FDate;
    property Text : String read FText write FText;
    property Bid : Extended read FBid write FBid;
    property RowID : String read FRowID write FRowID;
  end;

type
  TPaperTalk = class(TObject)
  private
    FPaperTalkItems : TObjectList;
  protected
  public
    constructor Create; overload;
    destructor Destroy;
    Procedure InsertItem(APerson : string; ATeam : string; APlayer : string; ADate : TDateTime; AText : String; ABid : Extended);
    Procedure LoadItems;

    property PaperTalkItems : TObjectList read FPaperTalkItems write FPaperTalkItems;
  published
  end;

var
 gPaperTalk : TPaperTalk;

implementation

uses DB;

constructor TPaperTalk.Create;
begin
  inherited;
  FPaperTalkItems := TObjectList.Create(true);
end;

destructor TPaperTalk.Destroy;
begin
  FPaperTalkItems.Free;
  inherited;
end;

Procedure TPaperTalk.InsertItem(APerson : string; ATeam : string; APlayer : string; ADate : TDateTime; AText : String; ABid : Extended);
var
  Qry : TOraQuery;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;

    Qry.SQL.Add('INSERT INTO PAPERTALK (PERSON,TEAM,PLAYER, DATEANDTIME, REASON,BID)');
    Qry.SQL.Add('VALUES (:PERSON,:TEAM,:PLAYER, :DATEANDTIME, :REASON,:BID)');
    Qry.ParamByName('PERSON').AsString := APerson;
    Qry.ParamByName('TEAM').AsString := ATeam;
    Qry.ParamByName('PLAYER').AsString := APlayer;
    Qry.ParamByName('DATEANDTIME').AsDateTime := ADate;
    Qry.ParamByName('REASON').AsString := AText;
    Qry.ParamByName('BID').AsFloat := ABid;
    Qry.ExecSQL;
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;
end;

Procedure TPaperTalk.LoadItems;
var
  Qry : TOraQuery;
  LPaperTalkItem : TPaperTalkItem;
begin
  try
    FPaperTalkItems.Clear;
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    Qry.SQL.Add('SELECT PERSON,TEAM,PLAYER, DATEANDTIME, REASON,BID FROM PAPERTALK');
    Qry.SQL.Add('ORDER BY DATEANDTIME');
    Qry.Open;
    while not qry.Eof do
    begin
      LPaperTalkItem := TPaperTalkItem.Create;
      LPaperTalkItem.Person := Qry.fieldByName('PERSON').AsString;
      LPaperTalkItem.Team := Qry.fieldByName('TEAM').AsString;
      LPaperTalkItem.Player := Qry.fieldByName('PLAYER').AsString;
      LPaperTalkItem.Date := Qry.fieldByName('DATEANDTIME').AsDateTime;
      LPaperTalkItem.Text := Qry.fieldByName('REASON').AsString;
      LPaperTalkItem.Bid := Qry.fieldByName('BID').AsFloat;

      LPaperTalkItem.RowID := LPaperTalkItem.Person +
        LPaperTalkItem.Team + LPaperTalkItem.Player +DateTimeToSTR(LPaperTalkItem.Date) +
        LPaperTalkItem.Text + FloatToStr(LPaperTalkItem.Bid);

      FPaperTalkItems.Add(LPaperTalkItem);
      Qry.Next;
    end;    // while
    Qry.Free;
  except
    raise;
  end;
end;

end.
