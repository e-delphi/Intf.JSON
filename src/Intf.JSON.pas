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
    procedure SetJSON(sJSON: Variant);
    function GetAsJSON: TJSONObject;
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONObject read GetAsJSON;
  end;

  IJSONArray = interface
    ['{F355D877-A18E-4D12-91FC-1BC44731AF3C}']
    function GetJSON: Variant;
    procedure SetJSON(sJSON: Variant);
    function GetAsJSON: TJSONArray;
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONArray read GetAsJSON;
  end;

type
  TIJSONObject = class(TInterfacedObject, IJSONObject)
  private
    FObjectJSON: TJSONObject;
    FVariant: Variant;
    function GetJSON: Variant;
    procedure SetJSON(sJSON: Variant);
    function GetAsJSON: TJSONObject;
  public
    constructor Create; overload;
    constructor Create(sJSON: String); overload;
    constructor Create(joJSON: TJSONObject); overload;
    destructor Destroy; override;
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONObject read GetAsJSON;
    class function New: Variant;
  end;

  TIJSONArray = class(TInterfacedObject, IJSONArray)
  private
    FObjectJSON: TJSONArray;
    FVariant: Variant;
    function GetJSON: Variant;
    procedure SetJSON(sJSON: Variant);
    function GetAsJSON: TJSONArray;
  public
    constructor Create; overload;
    destructor Destroy; override;
    property JSON: Variant read GetJSON write SetJSON;
    property AsJSON: TJSONArray read GetAsJSON;
  end;

implementation

uses
  System.Variants,
  System.DateUtils,
  System.Generics.Collections;

type
  TVarDataRecordType = class(TInvokeableVariantType)
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
  I: Integer;
  jvItem: TJSONValue;
begin
  Result := False;
  if TVarDataRecordData(V).JSON is TJSONObject then
  begin
    for I := 0 to Pred(TJSONObject(TVarDataRecordData(V).JSON).Count) do
    begin
      if TJSONObject(TVarDataRecordData(V).JSON).Pairs[I].JsonString.Value.ToLower.Equals(Name.ToLower) then
      begin
        jvItem := TJSONObject(TVarDataRecordData(V).JSON).Pairs[I].JsonValue;

        if jvItem is TJSONString then
          Variant(dest) := TJSONString(jvItem).Value
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
        Break;
      end;
    end;
  end
  else
  if TVarDataRecordData(V).JSON is TJSONArray then
  begin
    if Name.ToLower.Equals('count') then
      Variant(dest) := TJSONArray(TVarDataRecordData(V).JSON).Count;
  end;
end;

function TVarDataRecordType.SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean;
var
  I: Integer;
  sNomePar: String;
  jvItem: TJSONValue;
begin
  Result := True;

  case Value.VType of
    1: jvItem := TJSONNull.Create;
    7: jvItem := TJSONString.Create(DateToISO8601(Variant(Value)));
    8,256,258:  jvItem := TJSONString.Create(Variant(Value));
    2,3,4,5,6,16,17,18,19,20,21:  jvItem := TJSONNumber.Create(Variant(Value));
    11: jvItem := TJSONBool.Create(Variant(Value));
    271: jvItem := TJSONValue(Value.VPointer);
  else
    raise Exception.Create('Tipo não esperado!');
  end;

  if TVarDataRecordData(V).JSON is TJSONObject then
  begin
    for I := 0 to Pred(TJSONObject(TVarDataRecordData(V).JSON).Count) do
    begin
      if TJSONObject(TVarDataRecordData(V).JSON).Pairs[I].JsonString.Value.ToUpper.Equals(Name.ToUpper) then
      begin
        sNomePar := TJSONObject(TVarDataRecordData(V).JSON).Pairs[I].JsonString.Value;
        TJSONObject(TVarDataRecordData(V).JSON).RemovePair(sNomePar).Free;
        Break;
      end;
    end;

    if sNomePar.IsEmpty then
      sNomePar := Name.ToLower;

    TJSONObject(TVarDataRecordData(V).JSON).AddPair(sNomePar, jvItem);
  end
  else
  if TVarDataRecordData(V).JSON is TJSONArray then
    TJSONArray(TVarDataRecordData(V).JSON).AddElement(jvItem);
end;

function TVarDataRecordType.DoFunction(var Dest: TVarData; const V: TVarData; const Name: string; const Arguments: TVarDataArray): Boolean;
var
  jvItem: TJSONValue;
  Value: TVarData;
  intfA: TIJSONArray;
begin
  Result := True;

  if TVarDataRecordData(V).JSON is TJSONObject then
  begin
    if Length(Arguments) > 1 then
    begin
      intfA := TIJSONArray.Create; 
      for Value in Arguments do
        SetProperty(TVarData(intfA.JSON), 'add', Value);
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
      begin
        SetProperty(V, Name, Value);
        Variant(dest) := JSON2Variant(TVarDataRecordData(V).JSON);
      end;
    end;
  end;
end;

{ TIJSONObject }

class function TIJSONObject.New: Variant;
begin
  Result := TIJSONObject.Create.JSON;
end;

constructor TIJSONObject.Create(sJSON: String);
begin
  FObjectJSON := TJSONObject(TJSONObject.ParseJSONValue(sJSON));
end;

constructor TIJSONObject.Create(joJSON: TJSONObject);
begin
  FObjectJSON := joJSON;
end;

constructor TIJSONObject.Create;
begin
  inherited;
  FObjectJSON := TJSONObject.Create;
end;

destructor TIJSONObject.Destroy;
begin
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

procedure TIJSONObject.SetJSON(sJSON: Variant);
begin
  if Assigned(FObjectJSON) then
    FreeAndNil(FObjectJSON);

  if VarIsStr(sJSON) then
    FObjectJSON := TJSONObject(TJSONObject.ParseJSONValue(sJSON))
  else
    raise Exception.Create('Informe uma string com o JSON!');
end;

{ TIJSONArray }

constructor TIJSONArray.Create;
begin
  inherited;
  FObjectJSON := TJSONArray.Create;
end;

destructor TIJSONArray.Destroy;
begin
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

procedure TIJSONArray.SetJSON(sJSON: Variant);
begin
  if Assigned(FObjectJSON) then
    FreeAndNil(FObjectJSON);

  if VarIsStr(sJSON) then
    FObjectJSON := TJSONArray(TJSONObject.ParseJSONValue(sJSON))
  else
    raise Exception.Create('Informe uma string com o JSON!');
end;

initialization
  VarDataRecordType := TVarDataRecordType.Create;

finalization
  FreeAndNil(VarDataRecordType);

end.
