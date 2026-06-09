unit Excel;

interface

uses
  Windows, Classes, SysUtils, Excel_TLB;

const
  LCIDEnglishUSA = 1033;

type
  EFormat = (foNone, foExcel, foText, foCSV);

type
  TExcel = class(TObject)
  private
    FoleTrue : OleVariant;
    FoleFalse : OleVariant;
    FoleEmpty : OleVariant;
    FoleDelimiter : Array[EFormat] of OleVariant;
    FLCID : Integer;
    FExcel    : _Application;
    FBook     : _WorkBook;
    FWorksheet : _WorkSheet;
    function GetCell(AColumn,ARow : Integer) : Variant;
    procedure SetCell(AColumn,ARow : Integer; AValue : Variant);
  protected
  public
    constructor Create;
    destructor  Destroy; override;

    procedure Start;
    procedure Open(AFilename : String; AFormat : EFormat);
    procedure Close(AFilename : String; ASave : Boolean);
    procedure Quit;

    function  Rows : Integer;
    function  Columns : Integer;
    property Cell[AColumn,ARow : Integer] : Variant read GetCell write SetCell;
  published
  end;

implementation

function TExcel.GetCell(AColumn,ARow : Integer) : Variant;
begin
  result := FWorksheet.Cells[ARow,AColumn];
end;

procedure TExcel.SetCell(AColumn,ARow : Integer; AValue : Variant);
begin
  FWorksheet.Cells[ARow,AColumn] := AValue;
end;

constructor TExcel.Create;
begin
  inherited Create;
  FoleTrue := True;
  FoleFalse := False;
  TVarData(FoleEmpty).VType := varError;
{$IFDEF VER140}
  TVarData(FoleEmpty).VError := LongWord(DISP_E_PARAMNOTFOUND);
{$ELSE}
  TVarData(FoleEmpty).VError := DISP_E_PARAMNOTFOUND;
{$ENDIF}
  FoleDelimiter[foNone] := FoleEmpty;
  FoleDelimiter[foExcel] := FoleEmpty;
  FoleDelimiter[foText] := #9;
  FoleDelimiter[foCSV] := ',';
  FLCID := GetUserDefaultLCID;
end;

destructor TExcel.Destroy;
begin
  inherited Destroy;
end;

procedure TExcel.Start;
begin

end;

procedure TExcel.Open(AFilename : String; AFormat : EFormat);
begin
  try
    FExcel := coApplication.Create;
    try
      FBook := FExcel.Workbooks.Open(AFilename,FoleEmpty,FoleFalse,FoleEmpty,FoleEmpty,FoleEmpty,FoleEmpty,FoleEmpty,FoleDelimiter[AFormat],{FoleEmpty,}FoleEmpty,FoleEmpty,FoleEmpty,FoleFalse,FLCID);
    except
      on E:Exception do begin
      end;
    end;
    if not assigned(FBook) then begin
     {if failed with local setting try english(USA) in LCID}
      try
        FBook := FExcel.Workbooks.Open(AFilename,FoleEmpty,FoleFalse,FoleEmpty,FoleEmpty,FoleEmpty,FoleEmpty,FoleEmpty,FoleDelimiter[AFormat],{FoleEmpty,}FoleEmpty,FoleEmpty,FoleEmpty,FoleFalse,LCIDEnglishUSA);
      except
        on E:Exception do begin
        end;
      end;
    end;
    FWorkSheet := FBook.Worksheets.Item[1] as _WorkSheet;
  except
    on E:Exception do begin
    end;
  end;
end;

procedure TExcel.Close(AFilename : String; ASave : Boolean);
begin
  if ASave then
//    FExcel.Save(AFilename,FLCID)
    FBook.Close(FoleTrue,FoleEmpty,FoleEmpty,FLCID)
  else
    FBook.Close(FoleFalse,FoleEmpty,FoleEmpty,FLCID);

  FWorkSheet := Nil;
  FBook := Nil;
  FExcel.Quit;
  FExcel := Nil;
end;

procedure TExcel.Quit;
begin
  if assigned(FExcel) then begin
    FExcel.Quit;
    FExcel := Nil;
  end;
end;

function  TExcel.Rows : Integer;
begin
  result := FWorksheet.UsedRange[FLCID].Rows.Count;
end;

function  TExcel.Columns : Integer;
begin
  result := FWorksheet.UsedRange[FLCID].Columns.Count;
end;

end.
