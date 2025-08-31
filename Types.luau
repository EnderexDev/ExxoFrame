--!strict
--!native
--!optimize 2
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = ReplicatedStorage:WaitForChild("Utils")

export type PlayerGUI = typeof(game:GetService("StarterGui"))
export type MainUI = typeof(game:GetService("StarterGui"):WaitForChild("MainUI"))
export type MainFrames = typeof(game:GetService("StarterGui"):WaitForChild("MainUI"):WaitForChild("MainFrames"))
export type HUD = typeof(game:GetService("StarterGui"):WaitForChild("HUD"))
export type Inset = typeof(game:GetService("StarterGui"):WaitForChild("Inset"))

export type PlayerData = typeof(require(script.Parent.DefaultData))
export type PlayerUtil = typeof(require(Utils.Player))
export type InstanceUtil = typeof(require(Utils.Instance))
export type OutputUtil = typeof(require(Utils.Output))
export type NumberUtil = typeof(require(Utils.Number))
export type SoundUtil = typeof(require(Utils.Sound))
export type TableUtil = typeof(require(Utils.Table))
export type FrameUtil = typeof(require(Utils.Frame))
export type CollisionGroupsUtil = typeof(require(Utils.CollisionGroups))
export type GlobalSettingsUtil = typeof(require(Utils.GlobalSettings))
export type EffectsUtil = typeof(require(Utils.Effects))
export type ColorsUtil = typeof(require(Utils.Colors))

export type NewPlayerType = typeof(require(game:GetService("ServerScriptService"):WaitForChild("Core"):WaitForChild("NewPlayer")))
export type FramesControllerType = typeof(require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Cores"):WaitForChild("FramesController")))

type Connection = {
    Disconnect: (self: Connection) -> (),
    Connected: boolean,
}

export type ClientBridge = {
    Fire: (self: ClientBridge, Player: Player, ModuleName: string, FunctionName: string, ...any) -> (),
    FireAll: (self: ClientBridge, ModuleName: string, FunctionName: string, ...any) -> (),
    FireSpecific: (self: ClientBridge, PlayersToFire: { Player }, ModuleName: string, FunctionName: string, ...any) -> (),
    FireExcept: (self: ClientBridge, PlayersToNotFire: { Player }, ModuleName: string, FunctionName: string, ...any) -> (),
    FireSelf: (self: ClientBridge, ModuleName: string, FunctionName: string, ...any) -> (),
}

export type ServerBridge = {
    Fire: (self: ServerBridge, ModuleName: string, FunctionName: string, ...any) -> (),
    FireSelf: (self: ServerBridge, ModuleName: string, FunctionName: string, ...any) -> (),
}

export type Loop = {
    Fire: (self: Loop) -> (),
    Connect: (self: Loop, func: () -> ()) -> Connection,
    Disconnect: (self: Loop) -> (),
}

export type CharacterConnection = Loop

export type ExxoFrame = {
    GameVersion: number,
    StartTime: number,

    Server: ServerBridge,
    Client: ClientBridge,

    FastLoop: Loop,
    HalfLoop: Loop,
    SecondLoop: Loop,
    MinuteLoop: Loop,

    Player: PlayerType,
    Instance: InstanceType,
    Output: OutputType,
    Number: NumberType,
    Sound: SoundType,
    Table: TableType,
    Frame: FrameType,
    CollisionGroups: CollisionGroupsType,
    GlobalSettings: GlobalSettingsType,
    Effects: EffectsType,
    Colors: ColorsType,
    FramesController: FramesControllerType,

    PlayerGUI: PlayerGUI,
    MainUI: MainUI,
    MainFrames: MainFrames,
    HUD: HUD,
    Inset: Inset,
    
    ReferenceModules: { [string]: any },
    Services: { [string]: any },
    Components: { [string]: any },
    UserFrames: { [string]: any },
    Animations: { [string]: any },
    Data: PlayerData,

    GetCharacter: () -> Character?,
    GetMouse: () -> Mouse?,
    GetDevice: () -> "CONSOLE" | "PC" | "MOBILE",
    CharacterAdded: CharacterConnection,
    CharacterRemoved: CharacterConnection,

    IsPremium: () -> boolean,
    ServerShutdown: boolean,

    NewPlayer: NewPlayerType,
    ThreadHandler: (Function: () -> ()) -> (),
}

return nil