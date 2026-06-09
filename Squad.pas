unit Squad;

interface

uses
  Windows, Classes, SysUtils, Contnrs, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Utilities, Constants, Database, Player;

type
  TSquad = class(TObject)
  private
    FPersonID : Integer;
    FSquadID : Integer;
    FPlayerID : Integer;
    FFromAt : TDateTime; {In team from, or want to be in team from}
    FUntilAt : TDateTime;
    FBid : Extended; {Millions}
    FValid : Boolean; {Bid successful!}
    FPlaying : Boolean;
    function GetPlayer: TPlayer;
  protected
  public
    constructor Create; overload;
    constructor Create(APersonID,ASquadID,APlayerID : Integer; AFromAt,AUntilAt : TDateTime; ABid : Extended; AValid : Boolean); overload;
    destructor  Destroy; override;

    procedure Delete;
    procedure Load(AFrom : TOraQuery);
    procedure Save;

    property PersonID : Integer read FPersonID write FPersonID;
    property SquadID : Integer read FSquadID;
    property PlayerID : Integer read FPlayerID write FPlayerID;
    property FromAt : TDateTime read FFromAt write FFromAt;
    property UntilAt : TDateTime read FUntilAt write FUntilAt;
    property Bid : Extended read FBid write FBid;
    property Valid : Boolean read FValid write FValid;
    property Playing : Boolean read FPlaying write FPlaying;
    property Player : TPlayer read GetPlayer;
  published
  end;

  TSquads = class(TObject)
  private
    FItems : TObjectList;
    function GetSquad(AIndex : Integer) : TSquad;
  protected
  public
    constructor Create(AOwns : Boolean = False);
    destructor  Destroy; override;

    procedure Add(ASquad : TSquad);
    procedure Clear;

    function  Find(ASquadID : Integer) : TSquad; 
    function  IndexOf(ASquadID : Integer) : Integer;
    procedure Sort;

    procedure Save;
    procedure Load;

    property Squad[AIndex : Integer] : TSquad read GetSquad; default;
    function Count : Integer;
  published
  end;

implementation

{ TSquad }

constructor TSquad.Create;
begin
  inherited Create;
end;

constructor TSquad.Create(APersonID,ASquadID,APlayerID : Integer; AFromAt,AUntilAt : TDateTime; ABid : Extended; AValid : Boolean);
var
  Qry : TOraQuery;
begin
  Create;
  FPersonID := APersonID;
  FSquadID := ASquadID;
  FPlayerID := APlayerID;
  FFromAt := AFromAt;
  FUntilAt := AUntilAt;
  FBid := ABid;
  FValid := AValid;

  if FSquadID=-1 then begin
    dmData.Start;
    try
      {Need to create!}
      Qry := TOraQuery.Create(Nil);
      Qry.Session := dmData.dbDream;
      with Qry,SQL do begin
        Add('SELECT MAX(SquadID)+1 FROM SQUAD');
        Open;
        FSquadID := Fields[0].AsInteger;
        Close;
        Clear;
      end;    { with }

      with Qry,SQL do begin
        Add('INSERT INTO SQUAD (SQUADID,PERSONID,PLAYERID,FROMAT,UNTILAT,BID,VALID,PLAYING) VALUES');
        Add('(:SQUADID,:PERSONID,:PLAYERID,:FROMAT,:UNTILAT,:BID,:VALID,:PLAYING)');
        ParamByName('PERSONID').AsInteger := FPersonID;
        ParamByName('SQUADID').AsInteger := FSquadID;
        ParamByName('PLAYERID').AsInteger := FPlayerID;
        ParamByName('FROMAT').AsDateTime := FFromAt;
        ParamByName('UNTILAT').AsDateTime := FUntilAt;
        ParamByName('BID').AsFloat := FBid;
        ParamByName('VALID').AsString := gcTorF[FValid];
        ParamByName('PLAYING').AsString := gcTorF[FPlaying];
        ExecSQL;
      end;
      Qry.Free;
      dmData.Commit;
    except
      dmData.Rollback;
      raise;
    end;  
  end;
end;

destructor TSquad.Destroy;
begin
  inherited;
end;

procedure TSquad.Load(AFrom : TOraQuery);
begin
  with AFrom,SQL do begin
    FPersonID := FieldByName('PERSONID').AsInteger;
    FSquadID := FieldByName('SQUADID').AsInteger;
    FPlayerID := FieldByName('PLAYERID').AsInteger;
    FFromAt := FieldByName('FROMAT').AsDateTime;
    FUntilAt := FieldByName('UNTILAT').AsDateTime;
    FBid := FieldByName('BID').AsFloat;
    FValid := FieldByName('VALID').AsBoolean;
    FPlaying := FieldByName('PLAYING').AsBoolean;
  end;
end;

procedure TSquad.Save;
var
  Qry : TOraQuery;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
//    if FValid then begin
      with Qry,SQL do begin
        Add('UPDATE SQUAD SET UNTILAT=:UNTILAT, FROMAT=:FROMAT, VALID=:VALID, BID=:BID, PLAYING=:PLAYING WHERE SQUADID=:SQUADID');
        ParamByName('SQUADID').AsInteger := FSquadID;
        ParamByName('FROMAT').AsDateTime := FFromAt;
        ParamByName('UNTILAT').AsDateTime := FUntilAt;
        ParamByName('VALID').AsString := gcTorF[FValid];
        ParamByName('BID').AsFloat := FBid;
        ParamByName('PLAYING').AsString := gcTorF[FPlaying];
        ExecSQL;
      end;
//    end else begin
//      with Qry,SQL do begin
//        Add('DELETE FROM SQUAD WHERE SQUADID=:SQUADID');
//        ParamByName('SQUADID').AsInteger := FSquadID;
//        ExecSQL;
//      end;
//    end;
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;
end;

procedure TSquad.Delete;
var
  Qry : TOraQuery;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('DELETE FROM SQUAD WHERE SQUADID=:SQUADID');
      ParamByName('SQUADID').AsInteger := FSquadID;
      ExecSQL;
    end;
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;
end;

function TSquad.GetPlayer: TPlayer;
var
  C : Integer;
begin
  result := Nil;
  for C := 0 to gPlayers.Count-1 do { Iterate } begin
    if gPlayers[C].PlayerID=FPlayerID then begin
      result := gPlayers[C];
      break;
    end;
  end;    { for }
end;

{ TSquads }

function TSquads.GetSquad(AIndex: Integer): TSquad;
begin
  result := FItems[AIndex] as TSquad;
end;

constructor TSquads.Create(AOwns : Boolean = False);
begin
  inherited Create;
  FItems := TObjectList.Create(AOwns);
end;

destructor TSquads.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TSquads.Add(ASquad: TSquad);
begin
  FItems.Add(ASquad);
end;

procedure TSquads.Clear;
begin
  FItems.Clear;
end;

function Compare(Item1, Item2: Pointer): Integer;
var
  P1,P2 : TSquad;
begin
  P1 := Item1;
  P2 := Item2;
  result := P1.SquadID-P2.SquadID;
end;

function  TSquads.IndexOf(ASquadID : Integer) : Integer;
var
  C : Integer;
begin
  result := -1;
  for C := 0 to FItems.Count-1 do { Iterate } begin
    if Squad[C].SquadID=ASquadID then begin
      result := C;
      break;
    end;
  end;    { for }
end;

function TSquads.Find(ASquadID : Integer) : TSquad;
var
  Idx : Integer;
begin
  result := Nil;
  Idx := IndexOf(ASquadID);
  if Idx>=0 then
    result := FItems[Idx] as TSquad;
end;

procedure TSquads.Sort;
begin
  FItems.Sort(Compare);
end;

procedure TSquads.Save;
begin
end;

procedure TSquads.Load;
var
  Play : TSquad;
  Qry : TOraQuery;
begin
  Clear;
  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry do begin
    SQL.Add('SELECT * FROM Squad ORDER BY SquadID');
    Open;
    while not Eof do begin
      Play := TSquad.Create;
      Play.Load(Qry);
      Add(Play);
      SetToNil(Play);
      Next;
    end;    { while }
    Close;
  end;    { with }
  Qry.Free;
end;

function TSquads.Count: Integer;
begin
  result := FItems.Count;
end;

end.
