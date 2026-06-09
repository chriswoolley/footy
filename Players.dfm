object FrmPlayers: TFrmPlayers
  Left = 327
  Top = 320
  Width = 721
  Height = 481
  Caption = 'Players'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object grdPlayers: TdxDBGrid
    Left = 0
    Top = 41
    Width = 713
    Height = 406
    Bands = <
      item
      end>
    DefaultLayout = True
    HeaderPanelRowCount = 1
    KeyField = 'PlayerID'
    ShowGroupPanel = True
    SummaryGroups = <>
    SummarySeparator = ', '
    Align = alClient
    TabOrder = 0
    OnDblClick = grdPlayersDblClick
    DataSource = dsPlayers
    Filter.Active = True
    Filter.AutoDataSetFilter = True
    Filter.CaseInsensitive = True
    Filter.Criteria = {00000000}
    OptionsBehavior = [edgoAutoSearch, edgoAutoSort, edgoCaseInsensitive, edgoDragScroll, edgoImmediateEditor, edgoMultiSort, edgoTabThrough, edgoVertThrough]
    OptionsDB = [edgoCancelOnExit, edgoCanNavigation, edgoLoadAllRecords, edgoSmartRefresh, edgoSmartReload, edgoUseBookmarks]
    OptionsView = [edgoAutoCalcPreviewLines, edgoBandHeaderWidth, edgoIndicator, edgoPreview, edgoUseBitmap]
    PreviewFieldName = 'PlayerNotes'
    OnCustomDrawCell = grdPlayersCustomDrawCell
    object grdPlayersRecId: TdxDBGridColumn
      Visible = False
      BandIndex = 0
      RowIndex = 0
      FieldName = 'RecId'
    end
    object grdPlayersPlayerID: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'PlayerID'
    end
    object grdPlayersName: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Name'
    end
    object grdPlayersTeam: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Team'
    end
    object grdPlayersValue: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Value'
    end
    object grdPlayersPoints: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Points'
    end
    object grdPlayersRatioPoundsPerPoint: TdxDBGridColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'RatioPoundsPerPoint'
    end
    object grdPlayersRatioPointsPerPound: TdxDBGridColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'RatioPointsPerPound'
    end
    object grdPlayersType: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Type'
    end
    object grdPlayersUsed: TdxDBGridCheckColumn
      Width = 100
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Used'
      ValueChecked = 'True'
      ValueUnchecked = 'False'
    end
  end
  object pnlButton: TPanel
    Left = 0
    Top = 0
    Width = 713
    Height = 41
    Align = alTop
    TabOrder = 1
    object lblBid: TLabel
      Left = 376
      Top = 12
      Width = 15
      Height = 13
      Caption = 'Bid'
    end
    object Label1: TLabel
      Left = 200
      Top = 12
      Width = 44
      Height = 13
      Caption = 'Maximum'
    end
    object btnSelect: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Select'
      TabOrder = 0
      OnClick = btnSelectClick
    end
    object btnCancel: TButton
      Left = 88
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
    object edtBid: TEdit
      Left = 400
      Top = 8
      Width = 121
      Height = 21
      TabOrder = 2
    end
    object edtMax: TEdit
      Left = 248
      Top = 8
      Width = 121
      Height = 21
      ReadOnly = True
      TabOrder = 3
    end
    object btnExport: TButton
      Left = 632
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Export'
      TabOrder = 4
      OnClick = btnExportClick
    end
  end
  object dxmPlayers: TdxMemData
    Indexes = <>
    Persistent.Option = poNone
    SortOptions = []
    OnCalcFields = dxmPlayersCalcFields
    Left = 112
    Top = 232
    object dxmPlayersPlayerID: TIntegerField
      FieldName = 'PlayerID'
    end
    object dxmPlayersPlayerName: TStringField
      DisplayWidth = 20
      FieldName = 'Name'
      Size = 120
    end
    object dxmPlayersPlayerTeam: TStringField
      DisplayWidth = 20
      FieldName = 'Team'
      Size = 120
    end
    object dxmPlayersPlayerValue: TFloatField
      DisplayLabel = 'Price'
      FieldName = 'Value'
      DisplayFormat = #39#163#39'0.0'#39'm'#39
    end
    object dxmPlayersPlayerPoints: TIntegerField
      FieldName = 'Points'
    end
    object dxmPlayersRatioPoundsPerPoint: TFloatField
      DisplayLabel = 'Points/'#163
      FieldKind = fkCalculated
      FieldName = 'RatioPoundsPerPoint'
      DisplayFormat = '0.000000'
      Calculated = True
    end
    object dxmPlayersRatioPointsPerPound: TFloatField
      DisplayLabel = #163'/Point'
      FieldKind = fkCalculated
      FieldName = 'RatioPointsPerPound'
      DisplayFormat = '0.00'
      Calculated = True
    end
    object dxmPlayersType: TStringField
      FieldName = 'Type'
    end
    object dxmPlayersUsed: TBooleanField
      FieldName = 'Used'
    end
  end
  object dsPlayers: TDataSource
    DataSet = dxmPlayers
    Left = 184
    Top = 232
  end
  object dlgSave: TSaveDialog
    DefaultExt = '*.XLS'
    Filter = 'Excel Spreadsheet|*.XLS'
    Left = 384
    Top = 200
  end
end
