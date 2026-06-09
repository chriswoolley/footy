unit Previous;

interface

uses
  Windows, Classes, SysUtils, Contnrs, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Constants, Database, Utilities;

type
  TPrevious = class(TObject)
  private
    FPreviousID : Integer;
    FPlayerID : Integer;
    FPrice : Extended;
    FPoints : Integer;
  protected
  public
    constructor Create; overload;
    constructor Create(APlayerID : Integer; APrice : Extended; APoints : Integer); overload;
    destructor  Destroy; override;

    procedure Load(AFrom : TOraQuery);

    property PlayerID : Integer read FPlayerID;
    property Price : Extended read FPrice;
    property Points : Integer read FPoints;
  published
  end;

  TPreviouss = class(TObject)
  private
    FItems : TObjectList;
    function GetPrevious(AIndex : Integer) : TPrevious;
  protected
  public
    constructor Create;
    destructor  Destroy; override;

    procedure Add(APrevious : TPrevious);
    procedure Clear;

    function  Find(APlayerID : Integer) : TPrevious;
    function  IndexOf(APlayerID : Integer) : Integer;
    procedure Sort;

    procedure Load;

    property Previous[AIndex : Integer] : TPrevious read GetPrevious; default;
    function Count : Integer;
  published
  end;

var
  gPreviouss : TPreviouss;

implementation

{ TPrevious }

constructor TPrevious.Create;
begin
  inherited Create;
end;

constructor TPrevious.Create(APlayerID : Integer; APrice: Extended; APoints : Integer);
var
  Qry : TOraQuery;
begin
  Create;
  FPlayerID := APlayerID;
  FPrice := APrice;
  FPoints := APoints;

  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('SELECT NVL(MAX(PREVIOUSID),1) AS ID FROM PREVIOUS');
      Open;
      FPreviousID := FieldByName('ID').AsInteger;
      Close;
      Clear;
      Add('INSERT INTO PREVIOUS (PREVIOUSID,PLAYERID,PLAYERPRICE,PLAYERPOINTS) VALUES');
      Add('(:PREVIOUSID,:PLAYERID,:PLAYERPRICE,:PLAYERPOINTS)');
      ParamByName('PREVIOUSID').AsInteger := FPreviousID;
      ParamByName('PLAYERID').AsInteger := FPlayerID;
      ParamByName('PLAYERPRICE').AsFloat := FPrice;
      ParamByName('PLAYERPOINTS').AsInteger := FPoints;
      ExecSQL;
    end;
    Qry.Free;
    dmData.Commit;
  except  
    dmData.Rollback;
    raise;
  end;
end;

destructor TPrevious.Destroy;
begin
  inherited;
end;

procedure TPrevious.Load(AFrom : TOraQuery);
begin
  FPlayerID := AFrom.FieldByName('PlayerID').AsInteger;
  FPrice := AFrom.FieldByName('PlayerPrice').AsFloat;
  FPoints := AFrom.FieldByName('PlayerPOINTS').AsInteger;
end;

{ TPreviouss }

function TPreviouss.GetPrevious(AIndex: Integer): TPrevious;
begin
  result := FItems[AIndex] as TPrevious;
end;

constructor TPreviouss.Create;
begin
  inherited Create;
  FItems := TObjectList.Create;
end;

destructor TPreviouss.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TPreviouss.Add(APrevious: TPrevious);
begin
  FItems.Add(APrevious);
end;

procedure TPreviouss.Clear;
begin
  FItems.Clear;
end;

function Compare(Item1, Item2: Pointer): Integer;
var
  P1,P2 : TPrevious;
begin
  P1 := Item1;
  P2 := Item2;
  result := P1.PlayerID-P2.PlayerID;
end;

function  TPreviouss.IndexOf(APlayerID : Integer) : Integer;
var
  C : Integer;
begin
  result := -1;
  for C := 0 to FItems.Count-1 do { Iterate } begin
    if Previous[C].PlayerID=APlayerID then begin
      result := C;
      break;
    end;
  end;    { for }
end;

function TPreviouss.Find(APlayerID : Integer) : TPrevious;
var
  Idx : Integer;
begin
  result := Nil;
  Idx := IndexOf(APlayerID);
  if Idx>=0 then
    result := FItems[Idx] as TPrevious;
end;

procedure TPreviouss.Sort;
begin
  FItems.Sort(Compare);
end;

procedure TPreviouss.Load;
var
  Play : TPrevious;
  Qry : TOraQuery;
begin
  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry do begin
    SQL.Add('SELECT * FROM PREVIOUS ORDER BY PLAYERID');
    Open;
    while not Eof do begin
      Play := TPrevious.Create;
      Play.Load(Qry);
      Add(Play);
      SetToNil(Play);
      Next;
    end;    { while }
    Close;
  end;    { with }
  Qry.Free;
end;

function TPreviouss.Count: Integer;
begin
  result := FItems.Count;
end;

end.
