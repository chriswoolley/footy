object FrmDreamTeamScore: TFrmDreamTeamScore
  Left = 361
  Top = 150
  Width = 673
  Height = 174
  Caption = 'FrmDreamTeamScore'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object mmoStages: TMemo
    Left = 88
    Top = 64
    Width = 569
    Height = 65
    Lines.Strings = (
      
        'http://www.dreamteamfc.com/Sun/servlet/OpenFSELogin?homename=WC2' +
        '002&language=ENGLISH&aff_id=45'
      
        'http://www.dreamteamfc.com/Sun/servlet/PostPlayerList?catidx=1&t' +
        'itle=GOALKEEPERS&gameid=78'
      
        'http://www.dreamteamfc.com/Sun/servlet/PostPlayerList?catidx=2&t' +
        'itle=DEFENDERS&gameid=78'
      
        'http://www.dreamteamfc.com/Sun/servlet/PostPlayerList?catidx=3&t' +
        'itle=MIDFIELDERS&gameid=78'
      
        'http://www.dreamteamfc.com/Sun/servlet/PostPlayerList?catidx=4&t' +
        'itle=STRIKERS&gameid=78')
    TabOrder = 2
    Visible = False
  end
  object mmoHTML: TMemo
    Left = 0
    Top = 41
    Width = 665
    Height = 99
    Align = alClient
    TabOrder = 1
  end
  object webBrowse: TWebBrowser
    Left = 0
    Top = 41
    Width = 665
    Height = 99
    Align = alClient
    TabOrder = 0
    OnNavigateComplete2 = webBrowseNavigateComplete2
    OnDocumentComplete = webBrowseDocumentComplete
    ControlData = {
      4C000000BB4400003B0A00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126200000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object grdData: TdxDBGrid
    Left = 0
    Top = 41
    Width = 665
    Height = 99
    Bands = <
      item
      end>
    DefaultLayout = True
    HeaderPanelRowCount = 1
    KeyField = 'ID'
    ShowGroupPanel = True
    SummaryGroups = <>
    SummarySeparator = ', '
    Align = alClient
    TabOrder = 3
    DataSource = dsData
    Filter.Active = True
    Filter.AutoDataSetFilter = True
    Filter.CaseInsensitive = True
    Filter.Criteria = {00000000}
    OptionsDB = [edgoCancelOnExit, edgoCanDelete, edgoCanInsert, edgoCanNavigation, edgoConfirmDelete, edgoLoadAllRecords, edgoSmartRefresh, edgoSmartReload, edgoUseBookmarks]
    OptionsView = [edgoBandHeaderWidth, edgoIndicator, edgoUseBitmap]
    ShowRowFooter = True
    OnEdited = grdDataEdited
    object grdDataRecId: TdxDBGridColumn
      Visible = False
      Width = 72
      BandIndex = 0
      RowIndex = 0
      FieldName = 'RecId'
    end
    object grdDataID: TdxDBGridMaskColumn
      Width = 52
      BandIndex = 0
      RowIndex = 0
      FieldName = 'ID'
    end
    object grdDataName: TdxDBGridMaskColumn
      Width = 178
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Name'
    end
    object grdDataCountry: TdxDBGridMaskColumn
      Width = 136
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Country'
    end
    object grdDataCost: TdxDBGridMaskColumn
      Width = 78
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Cost'
    end
    object grdDataPoints1: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Points1'
    end
    object grdDataPoints2: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Points2'
    end
    object grdDataPoints3: TdxDBGridMaskColumn
      BandIndex = 0
      RowIndex = 0
      FieldName = 'Points3'
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 665
    Height = 41
    Align = alTop
    TabOrder = 4
    object btnUpdate: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Update'
      TabOrder = 0
      OnClick = btnUpdateClick
    end
    object btnToExcel: TButton
      Left = 96
      Top = 8
      Width = 75
      Height = 25
      Caption = 'ToExcel'
      TabOrder = 1
      OnClick = btnToExcelClick
    end
    object btnEdit: TButton
      Left = 184
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Edit'
      TabOrder = 2
      OnClick = btnEditClick
    end
    object edtDAT: TEdit
      Left = 384
      Top = 8
      Width = 121
      Height = 21
      TabOrder = 3
      Text = 'PLAYERS.DAT'
    end
    object edtXLS: TEdit
      Left = 512
      Top = 8
      Width = 121
      Height = 21
      TabOrder = 4
      Text = 'c:\dream.xls'
    end
    object btnWeb: TButton
      Left = 640
      Top = 8
      Width = 19
      Height = 25
      TabOrder = 5
      OnClick = btnWebClick
    end
    object btnSave: TButton
      Left = 272
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Save'
      TabOrder = 6
      OnClick = btnSaveClick
    end
  end
  object dxmData: TdxMemData
    Indexes = <>
    SortOptions = []
    Left = 288
    Top = 16
    object dxmDataID: TIntegerField
      FieldName = 'ID'
      ReadOnly = True
    end
    object dxmDataName: TStringField
      FieldName = 'Name'
      ReadOnly = True
    end
    object dxmDataCountry: TStringField
      FieldName = 'Country'
      ReadOnly = True
    end
    object dxmDataCost: TFloatField
      FieldName = 'Cost'
      ReadOnly = True
    end
    object dxmDataPoints1: TIntegerField
      FieldName = 'Points1'
    end
    object dxmDataPoints2: TIntegerField
      FieldName = 'Points2'
    end
    object dxmDataPoints3: TIntegerField
      FieldName = 'Points3'
    end
  end
  object dsData: TDataSource
    DataSet = dxmData
    Left = 352
    Top = 16
  end
end
