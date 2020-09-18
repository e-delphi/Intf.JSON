// Eduardo - 08/08/2020
unit Intf.JSON;

interface

uses
  System.JSON,
  System.SysUtils;

type
  IJSONObject = interface
    ['{54A1B884-F074-41EC-AE49-846571360A7E}']
    function GetJSON: Variant;
    procedure SetJSON(Value: Variant);
    function GetAsJSON: TJSONObject;
    function GetInstanceOwner: Boolean;
    procedure SetInstanceOwner(Value: Boolean);
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONObject read GetAsJSON;
    property InstanceOwner: Boolean read GetInstanceOwner write SetInstanceOwner;
  end;

  IJSONArray = interface
    ['{F355D877-A18E-4D12-91FC-1BC44731AF3C}']
    function GetJSON: Variant;
    procedure SetJSON(sJSON: Variant);
    function GetAsJSON: TJSONArray;
    function GetInstanceOwner: Boolean;
    procedure SetInstanceOwner(bInstanceOwner: Boolean);
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONArray read GetAsJSON;
    property InstanceOwner: Boolean read GetInstanceOwner write SetInstanceOwner;
  end;

type
  TObj = (obj);

  TIJSONObject = class(TInterfacedObject, IJSONObject)
  private
    FInstanceOwner: Boolean;
    FObjectJSON: TJSONObject;
    FVariant: Variant;
    function GetJSON: Variant;
    procedure SetJSON(Value: Variant);
    function GetAsJSON: TJSONObject;
    function GetInstanceOwner: Boolean;
    procedure SetInstanceOwner(Value: Boolean);
  public
    class function New(bInstanceOwner: Boolean = True): IJSONObject; overload;
    class function New(joJSON: TJSONObject; bInstanceOwner: Boolean = True): IJSONObject; overload;
    class function New(var Instance: IJSONObject; bInstanceOwner: Boolean = True): Variant; overload;
    class function New(sJSON: String; bInstanceOwner: Boolean = True): IJSONObject; overload;
    class function Init: Variant; overload;
    destructor Destroy; override;
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONObject read GetAsJSON;
    property InstanceOwner: Boolean read GetInstanceOwner write SetInstanceOwner;

  end;

  TIJSONArray = class(TInterfacedObject, IJSONArray)
  private
    FInstanceOwner: Boolean;
    FObjectJSON: TJSONArray;
    FVariant: Variant;
    function GetJSON: Variant;
    procedure SetJSON(Value: Variant);
    function GetAsJSON: TJSONArray;
    function GetInstanceOwner: Boolean;
    procedure SetInstanceOwner(Value: Boolean);
  public
    class function New(var Instance: IJSONArray; bInstanceOwner: Boolean = True): Variant;
    class function Init: Variant;
    destructor Destroy; override;
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONArray read GetAsJSON;
    property InstanceOwner: Boolean read GetInstanceOwner write SetInstanceOwner;
  end;

implementation

uses
  System.Variants,
  System.DateUtils,
  System.Generics.Collections;

type
  TVarDataRecordType = class(TInvokeableVariantType)
  protected
    function FixupIdent(const AText: string): string; override;
  public
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    function GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean; override;
    function SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean; override;
    function DoFunction(var Dest: TVarData; const V: TVarData; const Name: string; const Arguments: TVarDataArray): Boolean; override;
  end;

type
  TVarDataRecordData = packed record
    VType: TVarType;
    Reserved1, Reserved2, Reserved3: Word;
    JSON: TJSONValue;
    Reserved4: LongInt;
  end;

var
  VarDataRecordType: TVarDataRecordType = nil;

function JSON2Variant(oJSON: TJSONValue): Variant;
begin
  VarClear(Result);
  TVarDataRecordData(Result).VType := VarDataRecordType.VarType;
  TVarDataRecordData(Result).JSON := oJSON;
end;

procedure TVarDataRecordType.Clear(var V: TVarData);
begin
  SimplisticClear(V);
end;

procedure TVarDataRecordType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  SimplisticCopy(Dest, Source, Indirect);
end;

function TVarDataRecordType.GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean;
var
  jvItem: TJSONValue;
  dData: TDateTime;
begin
  Result := False;
  if TVarDataRecordData(V).JSON is TJSONObject then
  begin
    jvItem := TJSONObject(TVarDataRecordData(V).JSON).GetValue(Name);

    if jvItem is TJSONString then
    begin
      if (function(sText: String): Boolean
          begin
            Result :=
              (Length(sText) = 24) and
              (System.Copy(sText, 5,  1) = '-') and
              (System.Copy(sText, 8,  1) = '-') and
              (System.Copy(sText, 11, 1) = 'T') and
              (System.Copy(sText, 14, 1) = ':') and
              (System.Copy(sText, 17, 1) = ':') and
              (System.Copy(sText, 20, 1) = '.') and
              (System.Copy(sText, 24, 1) = 'Z');
          end)(TJSONString(jvItem).Value) and TryISO8601ToDate(TJSONString(jvItem).Value, dData) then
        Variant(dest) := dData
      else
        Variant(dest) := TJSONString(jvItem).Value
    end
    else
    if jvItem is TJSONNumber then
      Variant(dest) := TJSONNumber(jvItem).AsDouble
    else
    if jvItem is TJSONBool then
      Variant(dest) := TJSONBool(jvItem).AsBoolean
    else
    if (jvItem is TJSONObject) or (jvItem is TJSONArray) then
      Variant(dest) := JSON2Variant(jvItem)
    else
    if jvItem is TJSONNull then
      Variant(dest) := Null
    else
      raise Exception.Create('Tipo não esperado!');

    Result := True;
  end
  else
  if TVarDataRecordData(V).JSON is TJSONArray then
  begin
    if Name.ToLower.Equals('count') then
      Variant(dest) := TJSONArray(TVarDataRecordData(V).JSON).Count
    else
    if Name.ToLower.Equals('last') then
      Variant(dest) := JSON2Variant(TJSONArray(TVarDataRecordData(V).JSON).Items[Pred(TJSONArray(TVarDataRecordData(V).JSON).Count)]);
  end;
end;

function TVarDataRecordType.SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean;
var
  jvItem: TJSONValue;
begin
  Result := True;

  case Value.VType of
    1: jvItem := TJSONNull.Create;
    7: jvItem := TJSONString.Create(DateToISO8601(Variant(Value)));
    8,256,258,16392:  jvItem := TJSONString.Create(Variant(Value));
    2,3,4,5,6,16,17,18,19,20,21,16389:  jvItem := TJSONNumber.Create(Variant(Value));
    11: jvItem := TJSONBool.Create(Variant(Value));
    271, 275: jvItem := TJSONValue(Value.VPointer);
  else
    raise Exception.Create('Tipo não esperado!');
  end;

  if TVarDataRecordData(V).JSON is TJSONObject then
  begin
    TJSONObject(TVarDataRecordData(V).JSON).RemovePair(Name).Free;
    TJSONObject(TVarDataRecordData(V).JSON).AddPair(Name, jvItem);
  end
  else
  if TVarDataRecordData(V).JSON is TJSONArray then
    TJSONArray(TVarDataRecordData(V).JSON).AddElement(jvItem);
end;

function TVarDataRecordType.DoFunction(var Dest: TVarData; const V: TVarData; const Name: string; const Arguments: TVarDataArray): Boolean;
var
  jvItem: TJSONValue;
  Value: TVarData;
  intfA: IJSONArray;
begin
  Result := True;

  if TVarDataRecordData(V).JSON is TJSONObject then
  begin
    if Length(Arguments) > 1 then
    begin
      TIJSONArray.New(intfA);
      for Value in Arguments do
        SetProperty(TVarData(intfA.JSON), 'add', Value);
      intfA.InstanceOwner := False;
      SetProperty(V, Name, TVarData(intfA.JSON));
    end
    else
      SetProperty(V, Name, Arguments[0]);
    Variant(dest) := JSON2Variant(TVarDataRecordData(V).JSON);
  end
  else
  if TVarDataRecordData(V).JSON is TJSONArray then
  begin
    if Name.ToLower.Equals('item') then
    begin
      jvItem := TJSONArray(TVarDataRecordData(V).JSON).Items[Arguments[0].VInteger];
      if jvItem is TJSONNumber then
        Variant(dest) := TJSONNumber(jvItem).AsDouble
      else
      if jvItem is TJSONString then
        Variant(dest) := TJSONString(jvItem).Value
      else
      if jvItem is TJSONBool then
        Variant(dest) := TJSONBool(jvItem).AsBoolean
      else
      if jvItem is TJSONNull then
        Variant(dest) := Null
      else
      if (jvItem is TJSONObject) or (jvItem is TJSONArray) then
        Variant(dest) := JSON2Variant(jvItem)
      else
        raise Exception.Create('Tipo de objeto não esperado!');
    end
    else
    if Name.ToLower.Equals('add') then
    begin
      for Value in Arguments do
        SetProperty(V, Name, Value);
      Variant(dest) := JSON2Variant(TVarDataRecordData(V).JSON);
    end;
  end;
end;

function TVarDataRecordType.FixupIdent(const AText: string): string;
begin
  Result := AText;
end;

{ TIJSONObject }

class function TIJSONObject.Init: Variant;
begin
  Result := JSON2Variant(TJSONObject.Create);
end;

class function TIJSONObject.New(bInstanceOwner: Boolean = True): IJSONObject;
var
  Inst: TIJSONObject;
begin
  Inst := TIJSONObject.Create;
  Inst.FInstanceOwner := bInstanceOwner;
  Inst.FObjectJSON := TJSONObject.Create;
  Result := Inst;
end;

class function TIJSONObject.New(joJSON: TJSONObject; bInstanceOwner: Boolean = True): IJSONObject;
var
  Inst: TIJSONObject;
begin
  Inst := TIJSONObject.Create;
  Inst.FObjectJSON := joJSON;
  Inst.FInstanceOwner := bInstanceOwner;
  Result := Inst;
end;

class function TIJSONObject.New(var Instance: IJSONObject; bInstanceOwner: Boolean = True): Variant;
var
  Inst: TIJSONObject;
begin
  Inst := TIJSONObject.Create;
  Inst.FObjectJSON := TJSONObject.Create;
  Inst.FInstanceOwner := bInstanceOwner;
  Instance := Inst;
  Result := Instance.JSON;
end;

class function TIJSONObject.New(sJSON: String; bInstanceOwner: Boolean = True): IJSONObject;
var
  Inst: TIJSONObject;
begin
  Inst := TIJSONObject.Create;
  Inst.FInstanceOwner := bInstanceOwner;
  Inst.FObjectJSON := TJSONObject(TJSONObject.ParseJSONValue(sJSON));
  Result := Inst;
end;

destructor TIJSONObject.Destroy;
begin
  if FInstanceOwner then
    FreeAndNil(FObjectJSON);
  inherited;
end;

function TIJSONObject.GetAsJSON: TJSONObject;
begin
  Result := FObjectJSON;
end;

function TIJSONObject.GetJSON: Variant;
begin
  if not VarIsClear(FVariant) then
    Exit(FVariant);

  FVariant := JSON2Variant(Self.FObjectJSON);
  Result := FVariant;
end;

function TIJSONObject.GetInstanceOwner: Boolean;
begin
  Result := FInstanceOwner;
end;

procedure TIJSONObject.SetInstanceOwner(Value: Boolean);
begin
  FInstanceOwner := Value;
end;

procedure TIJSONObject.SetJSON(Value: Variant);
begin
  if Assigned(FObjectJSON) then
    FreeAndNil(FObjectJSON);

  if VarIsStr(Value) then
    FObjectJSON := TJSONObject(TJSONObject.ParseJSONValue(Value))
  else
    raise Exception.Create('Informe uma string com o JSON!');
end;

{ TIJSONArray }

class function TIJSONArray.Init: Variant;
begin
  Result := JSON2Variant(TJSONArray.Create);
end;

class function TIJSONArray.New(var Instance: IJSONArray; bInstanceOwner: Boolean = True): Variant;
var
  Inst: TIJSONArray;
begin
  Inst := TIJSONArray.Create;
  Inst.FObjectJSON := TJSONArray.Create;
  Inst.FInstanceOwner := bInstanceOwner;
  Instance := Inst;
  Result := Instance.JSON;
end;

destructor TIJSONArray.Destroy;
begin
  if FInstanceOwner then
    FreeAndNil(FObjectJSON);
  inherited;
end;

function TIJSONArray.GetAsJSON: TJSONArray;
begin
  Result := FObjectJSON;
end;

function TIJSONArray.GetJSON: Variant;
begin
  if not VarIsClear(FVariant) then
    Exit(FVariant);

  FVariant := JSON2Variant(Self.FObjectJSON);
  Result := FVariant;
end;

function TIJSONArray.GetInstanceOwner: Boolean;
begin
  Result := FInstanceOwner;
end;

procedure TIJSONArray.SetInstanceOwner(Value: Boolean);
begin
  FInstanceOwner := Value;
end;

procedure TIJSONArray.SetJSON(Value: Variant);
begin
  if Assigned(FObjectJSON) then
    FreeAndNil(FObjectJSON);

  if VarIsStr(Value) then
    FObjectJSON := TJSONArray(TJSONObject.ParseJSONValue(Value))
  else
    raise Exception.Create('Informe uma string com o JSON!');
end;

initialization
  VarDataRecordType := TVarDataRecordType.Create;

finalization
  FreeAndNil(VarDataRecordType);

end.
