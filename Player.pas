unit Player;

interface

uses
  Windows, Classes, SysUtils, Contnrs, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Math, Constants, Database, Utilities,
  Team;

type
  EPlayerType = (ptGoalkeeper, ptDefender, ptMidfielder, ptStriker);
  SPlayerType = set of EPlayerType;

const
  gsPlayerType : Array[EPlayerType] of String = ('Goalkeeper','Defender','Midfielder','Striker');

type
  TPlayer = class(TObject)
  private
    FPlayerID : Integer;
    FTeam : TTeam;
    FCode : Integer;
    FName : String;
    FPrice : Extended;
    FType  : EPlayerType;
    FPoints : Integer;
    FValid,
    FUsed : Boolean;

    FChanged : Boolean;
    procedure SetPoints(APoints : Integer);
    function GetTeamID : Integer;
    procedure SetTeamID(ATeamID : Integer);
  protected
  public
    constructor Create; overload;
    constructor Create(APlayerID : Integer; ATeamID : Integer; ACode : Integer; AName : String; APrice : Extended; AType : EPlayerType; APoints : Integer); overload;
    destructor  Destroy; override;

    procedure Load(AFrom : TOraQuery);
    function Check(APlayerID : Integer; ATeamID : Integer; ACode : Integer; AName : String; APrice : Extended; AType : EPlayerType; APoints : Integer; ALog : TStrings) : Boolean;
    procedure Save;

    property PlayerID : Integer read FPlayerID;
    property TeamID : Integer read GetTeamID write SetTeamID;
    property Team : TTeam read FTeam;
    property Code : Integer read FCode;
    property Name : String read FName;
    property Price : Extended read FPrice;
    property PlayerType : EPlayerType read FType;
    property Points : Integer read FPoints write SetPoints;
    property Valid : Boolean read FValid write FValid;
    property Used : Boolean read FUsed write FUsed;

    property Changed : Boolean read FChanged write FChanged;
  published
  end;

  TPlayers = class(TObject)
  private
    FItems : TObjectList;
    function GetPlayer(AIndex : Integer) : TPlayer;
  protected
  public
    constructor Create(AOwns : Boolean = False);
    destructor  Destroy; override;

    procedure Add(APlayer : TPlayer);
    procedure Clear;

    function  Find(APlayerID : Integer) : TPlayer;
    function  IndexOf(APlayerID : Integer; AByID : Boolean) : Integer;
    procedure Sort;

    procedure Save;
    procedure Load;

    property Player[AIndex : Integer] : TPlayer read GetPlayer; default;
    function Count : Integer;
  published
  end;

var
  gPlayers : TPlayers;

implementation

{ TPlayer }

procedure TPlayer.SetPoints(APoints : Integer);
begin
  if FPoints=APoints then
    exit;
  FPoints := APoints;
  FChanged := True;
end;

function TPlayer.GetTeamID : Integer;
begin
  if assigned(FTeam) then
    result := FTeam.TeamID
  else
    result := -1;
end;

procedure TPlayer.SetTeamID(ATeamID : Integer);
begin
  FTeam := gTeams.Find(ATeamID);
end;

constructor TPlayer.Create;
begin
  inherited Create;
  FChanged := False;
  FValid := False;
end;

constructor TPlayer.Create(APlayerID : Integer; ATeamID : Integer; ACode : Integer; AName : String; APrice: Extended; AType : EPlayerType; APoints : Integer);
var
  Qry : TOraQuery;
begin
  Create;
  FPlayerID := APlayerID;
  FCode := ACode;
  FName := AName;
  FTeam := gTeams.Find(ATeamID);
  FPrice := APrice;
  FType := AType;
  FPoints := APoints;
  FValid := False;

  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('INSERT INTO PLAYER (PLAYERID,NAME,CODE,TEAMID,VALUE,TYPE,POINTS,VALID,USED) VALUES');
      Add('(:PLAYERID,:NAME,:CODE,:TEAMID,:VALUE,:TYPE,:POINTS,:VALID,:USED)');
      ParamByName('PLAYERID').AsInteger := FPlayerID;
      ParamByName('TEAMID').AsInteger := FTeam.TeamID;
      ParamByName('NAME').AsString := FName;
      ParamByName('CODE').AsInteger := FCode;
      ParamByName('VALUE').AsFloat := FPrice;
      ParamByName('TYPE').AsInteger := Ord(FType);
      ParamByName('POINTS').AsInteger := FPoints;
      ParamByName('VALID').AsString := gcTorF[FValid];
      ParamByName('USED').AsString := gcTorF[FUsed];
      ExecSQL;
    end;
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;  
end;

destructor TPlayer.Destroy;
begin
  inherited;
end;

procedure TPlayer.Load(AFrom : TOraQuery);
begin
  FPlayerID := AFrom.FieldByName('PLAYERID').AsInteger;
  FName := AFrom.FieldByName('NAME').AsString;
  FCode := AFrom.FieldByName('CODE').AsInteger;
  TeamID := AFrom.FieldByName('TEAMID').AsInteger;
  FPrice := AFrom.FieldByName('VALUE').AsFloat;
  FType := EPlayerType(AFrom.FieldByName('TYPE').AsInteger);
  FPoints := AFrom.FieldByName('POINTS').AsInteger;
  FValid := AFrom.FieldByName('VALID').AsBoolean;
  FUsed := AFrom.FieldByName('USED').AsBoolean;
end;

function TPlayer.Check(APlayerID : Integer; ATeamID : Integer; ACode : Integer; AName : String; APrice : Extended; AType : EPlayerType; APoints : Integer; ALog : TStrings) : Boolean;
begin
  {Check if owt changed and if so change it and flag it up!}
  if (ACode<>FCode) or (FName<>AName) or (Team.TeamID<>ATeamID) or (FPrice<>APrice) or (FType<>AType) or (FPoints<>APoints) then begin
    FName := AName;
    FCode := ACode;
    TeamID := ATeamID;
    FPrice := APrice;
    FType := AType;
    FPoints := APoints;
//    FValid := AValid;
    if assigned(ALog) then
      ALog.Add(gsPlayerType[FType]+' '+FName+' of '+FTeam.Name+' updated, now has '+IntToStr(FPoints)+'.');
    Save;
    result := True;
  end else
    result := False;
end;

procedure TPlayer.Save;
var
  Qry : TOraQuery;
  Tmp : String;
  N1,N2,N3 : String;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('UPDATE PLAYER SET NAME=:NAME, CODE=:CODE, TEAMID=:TEAMID,');
      Add('VALUE=:VALUE, TYPE=:TYPE, USED=:USED,');
      Add('POINTS=:POINTS, VALID=:VALID');
      Add('WHERE PLAYERID=:PLAYERID');
      ParamByName('PLAYERID').AsInteger := FPlayerID;
      ParamByName('NAME').AsString := FName;
      ParamByName('CODE').AsInteger := FCode;
      ParamByName('TEAMID').AsInteger := FTeam.TeamID;
      ParamByName('VALUE').AsFloat := FPrice;
      ParamByName('TYPE').AsInteger := Ord(FType);
      ParamByName('POINTS').AsInteger := FPoints;
      ParamByName('VALID').AsString := gcTorF[FValid];
      ParamByName('USED').AsString := gcTorF[FUsed];
      ExecSQL;
    end;
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;  
end;
{ TPlayers }

function TPlayers.GetPlayer(AIndex: Integer): TPlayer;
begin
  result := FItems[AIndex] as TPlayer;
end;

constructor TPlayers.Create(AOwns : Boolean = False);
begin
  inherited Create;
  FItems := TObjectList.Create(AOwns);
end;

destructor TPlayers.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TPlayers.Add(APlayer: TPlayer);
begin
  FItems.Add(APlayer);
end;

procedure TPlayers.Clear;
begin
  FItems.Clear;
end;

function Compare(Item1, Item2: Pointer): Integer;
var
  P1,P2 : TPlayer;
begin
  P1 := Item1;
  P2 := Item2;
  result := P1.PlayerID-P2.PlayerID;
end;

function  TPlayers.IndexOf(APlayerID : Integer; AByID : Boolean) : Integer;
var
  C : Integer;
begin
  result := -1;
  if AByID then begin
    for C := 0 to FItems.Count-1 do { Iterate } begin
      if Player[C].PlayerID=APlayerID then begin
        result := C;
        break;
      end;
    end;    { for }
  end else begin
    for C := 0 to FItems.Count-1 do { Iterate } begin
      if Player[C].Code=APlayerID then begin
        result := C;
        break;
      end;
    end;    { for }
  end;
end;

function TPlayers.Find(APlayerID : Integer) : TPlayer;
var
  Idx : Integer;
begin
  result := Nil;
  Idx := IndexOf(APlayerID,True);
  if Idx>=0 then
    result := FItems[Idx] as TPlayer;
end;

procedure TPlayers.Sort;
begin
  FItems.Sort(Compare);
end;

procedure TPlayers.Save;
var
  C : Integer;
  Play : TPlayer;
  Qry : TOraQuery;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry do begin
      SQL.Add('UPDATE PLAYER SET POINTS=:POINTS WHERE PLAYERID=:PLAYERID');
      for C := 0 to FItems.Count-1 do { Iterate } begin
        Play := FItems[C] as TPlayer;
        if Play.Changed then begin
          ParamByName('PLAYERID').AsInteger := Play.PlayerID;
          ParamByName('POINTS').AsInteger := Play.Points;
          ExecSQL;
          Play.Changed := False;
        end;
      end;    { for }
    end;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;  
end;

procedure TPlayers.Load;
var
  Play : TPlayer;
  Qry : TOraQuery;
begin
  Clear;
  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry do begin
    SQL.Add('SELECT * FROM PLAYER ORDER BY PLAYERID');
    Open;
    while not Eof do begin
      Play := TPlayer.Create;
      Play.Load(Qry);
      Add(Play);
      SetToNil(Play);
      Next;
    end;    { while }
    Close;
  end;    { with }
  Qry.Free;
end;

function TPlayers.Count: Integer;
begin
  result := FItems.Count;
end;

end.
