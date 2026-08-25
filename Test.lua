-- ==============================================
--     ONYX KEY SYSTEM - PANDU HUB
-- ==============================================

local Onyx = loadstring(game:HttpGet("https://cdn.jnkie.com/OnyxUI.lua"))()

Onyx.Appearance = {
    Title = "Wisnu Hub",
    Subtitle = "Enter your key to continue",
    KeylessTitle = "Wisnu Hub",
    KeylessSubtitle = "No key required for this build - you're verified.",
    Icon = "rbxassetid://96848424314690",
}

Onyx.Links = {
    GetKey = "https://discord.gg/fZzN5HhFB",
    Discord = "https://discord.gg/fZzN5HhFB",
}

Onyx.Storage = {
    FileName = "WisnuHub_key",
    Remember = true,
    AutoLoad = true,
}

Onyx.Shop = {
    Enabled = false,
    Icon = "",
    Title = "Get Key",
    Subtitle = "Buy VIP key",
    ButtonText = "Buy",
    Link = "https://discord.gg/fZzN5HhFB"
}

-- ==============================================
-- SCRIPT UTAMA
-- ==============================================
local function MainScript()
    print("ðŸš€ MainScript dimulai")
    pcall(function()
        repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        print("âœ… Key valid! Script loaded!")

        -- LOAD OXIDELIB
        local Oxidelib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/Oxidelib/main/Oxidelib.lua"))()
        if not Oxidelib then error("Gagal load Oxidelib") end
        print("âœ… Oxidelib loaded")

        -- SERVICES
        local RunService     = game:GetService("RunService")
        local Workspace      = game:GetService("Workspace")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Lighting       = game:GetService("Lighting")
        local UserInputService = game:GetService("UserInputService")
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local Stats          = game:GetService("Stats")
        local TweenService   = game:GetService("TweenService")
        local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")
        local Camera         = workspace.CurrentCamera
        local GuiService     = game:GetService("GuiService")
        local TextChatService = game:GetService("TextChatService")
        local CollectionService = game:GetService("CollectionService")
        local HttpService    = game:GetService("HttpService")

        -- ========================================================================
        -- REMOTE REFERENCES
        -- ========================================================================
        local Remotes = ReplicatedStorage:WaitForChild("Remotes")
        local AttackEvent = Remotes:WaitForChild("Attacks"):WaitForChild("BasicAttack")
        local SkillCheckRemote = Remotes:WaitForChild("Generator"):WaitForChild("SkillCheckResultEvent")
        local SkillCheckEvent = Remotes:WaitForChild("Generator"):WaitForChild("SkillCheckEvent")
        local ToFItems = Remotes:FindFirstChild("Items")
        local ToFFolder = ToFItems and ToFItems:FindFirstChild("Twist of Fate")
        local ToFFireRemote = ToFFolder and ToFFolder:FindFirstChild("Fire")
        local FlashlightFolder = ToFItems and ToFItems:FindFirstChild("Flashlight")
        local GotBlindedRemote = FlashlightFolder and FlashlightFolder:FindFirstChild("GotBlinded")
        local EmoteRemote = Remotes:WaitForChild("EmoteHandler")
        local FastVaultRemote = Remotes:WaitForChild("Window"):WaitForChild("fastvault")

        -- ========================================================================
        -- HELPER FUNCTIONS
        -- ========================================================================
        local function GetRemote(path)
            local parts = {}
            for part in string.gmatch(path, "[^%.]+") do table.insert(parts, part) end
            local current = ReplicatedStorage
            for _, part in ipairs(parts) do
                if current then
                    current = current:FindFirstChild(part)
                    if not current then return nil end
                end
            end
            return current
        end

        local function GetGameValue(obj, name)
            if not obj then return nil end
            local attr = obj:GetAttribute(name)
            if attr ~= nil then return attr end
            local child = obj:FindFirstChild(name)
            if child then
                local ok, val = pcall(function() return child.Value end)
                if ok then return val end
            end
            return nil
        end

        local function IsMobile()
            return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        end

        local function GetPing()
            local ping = 0.08
            pcall(function()
                local s = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
                if s and s > 0 then ping = s end
            end)
            return math.clamp(ping, 0.03, 1.5)
        end

        local function getRoot()
            return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end

        local function IsSurvivor(p) return p and p.Team and p.Team.Name == "Survivors" end
        local function IsKiller(p)
            return p and p.Team and (p.Team.Name == "Killer" or p.Team.Name == "Killers" or p.Team.Name == "Murderer")
        end
        local function IsDowned(char)
            if not char then return false end
            return char:GetAttribute("Knocked") == true or char:GetAttribute("IsHooked") == true
        end

        local function toThumbnail(assetId)
            return "https://www.roblox.com/asset-thumbnail/image?assetId=" .. assetId .. "&width=420&height=420&format=png"
        end

        -- ========================================================================
        -- SILENT AIM CONFIG (OXIO)
        -- ========================================================================
        local AimConfig = {
            Aim_Silent = false,
            Pistol_BlockKnocked = false,
            Flash_Silent = false,
            Flash_YOffset = 8,
            LockAim = false,
            Pistol_Target = "Killer",
            Pistol_FOVMode = false,
            Pistol_ShowFOV = false,
            Pistol_FOV = 150,
            AIM_TargetPart = "Torso",
            HideSilentLaser = false,
        }
        local isChargingPistol = false
        local lockedPistolTarget = nil
        local currentTouchPistolInput = nil
        local pistolLaser = nil
        local isAimingFlash = false

        -- ========================================================================
        -- SILENT AIM FUNCTIONS
        -- ========================================================================
        local function getTargetPartObject(char)
            if AimConfig.AIM_TargetPart == "Head" then 
                return char:FindFirstChild("Head")
            elseif AimConfig.AIM_TargetPart == "Root" or AimConfig.AIM_TargetPart == "HumanoidRootPart" then 
                return char:FindFirstChild("HumanoidRootPart")
            else 
                return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") 
            end
        end

        local function getPistolTarget()
            local closestDist = (AimConfig.Pistol_ShowFOV and AimConfig.Pistol_FOVMode) and AimConfig.Pistol_FOV or math.huge
            local bestTarget = nil
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return nil end
            if AimConfig.Pistol_BlockKnocked and IsDowned(myChar) then return nil end
            
            local cam = workspace.CurrentCamera
            local mouseLocation = UserInputService:GetMouseLocation()
            local players = Players:GetPlayers()

            for _, p in ipairs(players) do
                if p ~= LocalPlayer and p.Character then
                    local isValidTarget = false
                    if AimConfig.Pistol_Target == "Killer" and IsKiller(p) then 
                        isValidTarget = true
                    elseif AimConfig.Pistol_Target == "Survivor" and not IsKiller(p) then 
                        isValidTarget = true 
                    elseif AimConfig.Pistol_Target == "SCP" then
                        -- cari SCP dari ESPCache.SCP (akan diisi nanti)
                        for obj in pairs(ESPCache.SCP) do
                            if obj and obj.Parent then
                                local part = obj:IsA("Model") and (obj:FindFirstChild(AimConfig.AIM_TargetPart) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                                if part then
                                    return part
                                end
                            end
                        end
                        return nil
                    end
                    
                    if isValidTarget then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 and not IsDowned(p.Character) then
                            local targetPart = getTargetPartObject(p.Character)
                            if targetPart then
                                local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                                if onScreen or not AimConfig.Pistol_FOVMode then
                                    local dist = AimConfig.Pistol_FOVMode 
                                        and (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude 
                                        or (targetPart.Position - myHRP.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        bestTarget = targetPart
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return bestTarget
        end

        local function getKillerTargetForFlash()
            local bestTarget = nil
            local closestDist = math.huge
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return nil end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsKiller(p) and p.Character then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and hrp and not IsDowned(p.Character) then
                        local dist = (hrp.Position - myHRP.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            bestTarget = hrp 
                        end
                    end
                end
            end
            return bestTarget
        end

        local function executeSilentAimFire()
            local targetPart = getPistolTarget()
            local myChar = LocalPlayer.Character
            if AimConfig.Pistol_BlockKnocked and IsDowned(myChar) then return end
            if targetPart and myChar then
                local myPart = myChar:FindFirstChild("HumanoidRootPart")
                if myPart then
                    local twistOfFate = myChar:FindFirstChild("Twist of Fate")
                    if twistOfFate then
                        local weaponArg = twistOfFate
                        local rightArm = twistOfFate:FindFirstChild("Right Arm")
                        if rightArm then
                            if rightArm:FindFirstChild("EmperorGun") then 
                                weaponArg = rightArm:FindFirstChild("EmperorGun")
                            elseif rightArm:FindFirstChild("gun") then 
                                weaponArg = rightArm:FindFirstChild("gun")
                            else 
                                weaponArg = rightArm 
                            end
                        end
                        local startPos = myPart.Position
                        local targetPos = targetPart.Position
                        local targetVel = targetPart.AssemblyLinearVelocity
                        targetVel = Vector3.new(targetVel.X, 0, targetVel.Z)
                        local distance = (targetPos - startPos).Magnitude
                        local bulletSpeed = 400
                        local timeToHit = distance / bulletSpeed
                        local predictedPos = targetPos + (targetVel * timeToHit)
                        local offset = Vector3.new(0, -2, 0)
                        local aimDirection = ((predictedPos + offset) - startPos).Unit
                        if ToFFireRemote then
                            pcall(function() ToFFireRemote:FireServer(weaponArg, aimDirection) end)
                        end
                    end
                end
            end
        end

        local function CreatePistolLaser()
            if pistolLaser then return end
            pistolLaser = Instance.new("Part")
            pistolLaser.Name = "VD_PistolLaser"
            pistolLaser.Material = Enum.Material.Neon
            pistolLaser.Color = Color3.fromRGB(255, 0, 0)
            pistolLaser.CanCollide = false
            pistolLaser.Anchored = true
            pistolLaser.CastShadow = false
            pistolLaser.Size = Vector3.new(0.05, 0.05, 1)
            pistolLaser.Transparency = 0
        end
        CreatePistolLaser()

        local PistolFOVCircle = Drawing.new("Circle")
        PistolFOVCircle.Color = Color3.fromRGB(255, 255, 255)
        PistolFOVCircle.Thickness = 1.5
        PistolFOVCircle.Filled = false
        PistolFOVCircle.Visible = false

        -- ========================================================================
        -- SILENT AIM INPUT HANDLER
        -- ========================================================================
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            local isTouch = (input.UserInputType == Enum.UserInputType.Touch)
            if gameProcessed and not isTouch then return end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if AimConfig.Aim_Silent then 
                    isChargingPistol = true 
                    lockedPistolTarget = getPistolTarget()
                end
                if AimConfig.Flash_Silent then
                    isAimingFlash = true
                end
            end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if AimConfig.Aim_Silent and isChargingPistol then 
                    executeSilentAimFire() 
                end
            end
            
            if isTouch then
                if AimConfig.Aim_Silent or AimConfig.Flash_Silent then
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if playerGui then
                        local survivorMob = playerGui:FindFirstChild("Survivor-mob")
                        if survivorMob then
                            local controls = survivorMob:FindFirstChild("Controls")
                            if controls then
                                local targetBtn = controls:FindFirstChild("Gui-mob") 
                                if targetBtn and targetBtn.Visible then
                                    local pos = input.Position
                                    local absPos = targetBtn.AbsolutePosition
                                    local absSize = targetBtn.AbsoluteSize
                                    if pos.X >= absPos.X and pos.X <= (absPos.X + absSize.X) and pos.Y >= absPos.Y and pos.Y <= (absPos.Y + absSize.Y) then
                                        if AimConfig.Aim_Silent then
                                            isChargingPistol = true
                                            currentTouchPistolInput = input
                                            lockedPistolTarget = getPistolTarget()
                                        end
                                        if AimConfig.Flash_Silent then
                                            isAimingFlash = true
                                            currentTouchPistolInput = input
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input, gameProcessed)
            local isTouchEnd = (input.UserInputType == Enum.UserInputType.Touch)
            
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if isChargingPistol then 
                    isChargingPistol = false 
                    lockedPistolTarget = nil
                end
                if isAimingFlash then
                    isAimingFlash = false
                end
            end
            
            if isTouchEnd and input == currentTouchPistolInput then
                if isChargingPistol then
                    isChargingPistol = false
                    currentTouchPistolInput = nil
                    executeSilentAimFire()
                    lockedPistolTarget = nil
                end
                if isAimingFlash then
                    isAimingFlash = false
                    currentTouchPistolInput = nil
                end
            end
        end)

        -- Keybind Target (K = Killer, J = Survivor, L = SCP)
        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.K then
                AimConfig.Pistol_Target = "Killer"
                Oxidelib:Notify({ Title = "Silent Aim", Content = "Target: Killer", Duration = 1 })
            elseif input.KeyCode == Enum.KeyCode.J then
                AimConfig.Pistol_Target = "Survivor"
                Oxidelib:Notify({ Title = "Silent Aim", Content = "Target: Survivor", Duration = 1 })
            elseif input.KeyCode == Enum.KeyCode.L then
                AimConfig.Pistol_Target = "SCP"
                Oxidelib:Notify({ Title = "Silent Aim", Content = "Target: SCP", Duration = 1 })
            end
        end)

        -- ========================================================================
        -- HOOK UNTUK MEMBLOKIR REMOTE (AntiBlind, AntiVault, AntiFall)
        -- ========================================================================
        local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if checkcaller() then
                if method == "FireServer" then
                    if Killer.AntiBlind and GotBlindedRemote and self == GotBlindedRemote then
                        local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
                        if isKiller then return nil end
                    end
                    if PlayerMods.AntiVault and self.Name == "VaultEvent" then return nil end
                    if PlayerMods.AntiFall and self.Name == "Fall" then return nil end
                end
            end
            return oldNamecall(self, ...)
        end)

        -- ========================================================================
        -- KONFIGURASI LAINNYA (ESP, Teleport, dll)
        -- ========================================================================
        local ESP = { Survivor = false, Killer = false, Generator = false, Pallet = false, Window = false, SCP = false, Distance = 5000 }
        local ESPStatus = { Enabled = false, ShowName = true, ShowDistance = true, ShowHealth = false, ShowItem = true, Radius = 100 }
        local TeleportIndex = { Generator = 1, Hook = 1, Gate = 1, Pallet = 1, Window = 1 }
        local ESPItems = { ["Twist of Fate"] = true, ["Bandage"] = true, ["Motion Tracker"] = true, ["Gate"] = true, ["Shadow Clone"] = true, ["Parrying Dagger"] = true }
        local TeamColors = { Killer = Color3.fromRGB(255,60,60), Survivor = Color3.fromRGB(60,255,120) }
        local Auto = { SkillCheck = false, SkillCheckMode = "Instant", Parry = false, ParryDistance = 15, FaceSensitivity = 0.7, RequireFacing = true, PalletDrop = false, PalletDropDist = 6 }
        local GenBypass = { Enabled = false, Button = nil, UI = nil, Cache = {}, CacheTimer = 0, Processed = {} }
        local FakeTag = { Enabled = false, Text = "[WISNU]", Color = "#00FFFF" }
        local FakeParry = { Enabled = false, Animation = "Enten", Keybind = Enum.KeyCode.V }
        local FakeParryAnimations = { Enten = "rbxassetid://127096285501517", Stopwatch = "rbxassetid://81793464499285", Fih = "rbxassetid://123307242865945", BloodShield = "rbxassetid://75939529748815" }
        local AutoFlee = { Enabled = false, DetectDistance = 50, Cooldown = 0.1 }
        local GunAim = { Enabled = false, Holding = false, TargetMode = "Killer", Strength = 1, Predict = true, PredictStrength = 0.12, FOV = 250, VisibilityCheck = true, AimPart = "HumanoidRootPart", Target = nil }
        local AttackAim = { Enabled = false, Holding = false, Strength = 1, Predict = true, PredictStrength = 0.12, FOV = 250, VisibilityCheck = true, AimPart = "HumanoidRootPart" }
        local SpearAim = { Enabled = false, Gravity = 50, Speed = 100, FOV = 250, AimPart = "HumanoidRootPart" }
        local Killer = { KillAll = false, KillRange = 500, BypassCooldown = false, BypassLeap = false, ThirdPerson = false, ThirdPersonWasActive = false, OriginalCameraType = nil, AntiBlind = false, BlockVaults = false }
        local Masked = { CurrentPower = "Cobra" }
        local MaskedPowers = { "Cobra", "Richter", "Brandon", "Rabbit", "Alex" }
        local CameraZoom = { UnlimitedZoom = false, MaxDistance = 1000, MinDistance = 0, FOVEnabled = false, FOV = 70, DefaultFOV = workspace.CurrentCamera.FieldOfView }
        local AutoStalk = { Enabled = false, StalkRange = 150 }
        local PlayerMods = { GodMode = false, AntiFall = false, AntiVault = false }
        local Movement = { JumpPowerEnabled = false, JumpPowerValue = 50, OriginalJumpPower = 50, WalkSpeedEnabled = false, WalkSpeedValue = 17.6, OriginalWalkSpeed = 16, NoClip = false }
        local FastVault = { Enabled = false, Speed = 1.2, ReplaceMap = { ["rbxassetid://83873880822918"] = "rbxassetid://136962284480779" } }
        local ParryRangeVisual = { Enabled = false, Color = Color3.fromRGB(255,80,80), Transparency = 0.9 }
        local Crosshair = { Enabled = false, Size = 8, Thickness = 2, Color = Color3.fromRGB(255,255,255), Style = "Plus", OffsetX = 0, OffsetY = 0 }
        local Visual = { Fullbright = false, NoShadow = false, Ambient = false, AmbientColor = Color3.fromRGB(255,255,255), Brightness = 2, ClockTime = 14, LowGraphics = false, NoScreenEffects = false, CleanSky = false }
        local Emote = { Selected = "Mannrobics" }
        local EmoteButton = { Show = false, GuiInstance = nil }
        local Config = { Surv_AutoParry = false, Surv_ParrySafety = false, Surv_ParryAggressive = false, Surv_ParryCircle = true, Surv_ParryRadius = 15, Surv_ParryFace = 0.7, Surv_AutoCrouch = false, Ignored_Skills_List = {} }
        local State = { ParryCooldown = false, ParryCooldownTime = 60, AttackAimMode = "Normal", UsedPallets = {}, FakeParryTrack = nil, FakeParryButton = nil, ParryCircle = nil, busy = false, created = false, LastCrosshairStyle = nil, KillerTarget = nil }
        local Timers = { lastESPUpdate = 0, lastKillerUpdate = 0, lastGodMode = 0, lastPalletScan = 0, lastPalletDrop = 0, lastVaultBlock = 0 }
        local ESPCache = { Objects = {}, Status = {}, SCP = {}, Generators = {}, Windows = {}, Pallets = {} }
        local OriginalLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows }
        local CrosshairDrawings = {}
        local DisabledEffects = {}
        local EmoteList = { "Mannrobics", "Arm Swing", "Schadenfreude", "Kyoufuu", "Backflip", "Griddy", "Friday Night", "Floating Rest", "OnePlays", "Quick Combo", "WarCry", "Wave" }
        local GeneratorColor = Color3.fromRGB(255,170,0)
        local PalletColor = Color3.fromRGB(74,255,181)
        local WindowColor = Color3.fromRGB(74,255,181)
        local SCPColor = Color3.fromRGB(255,0,0)
        local RayParams = RaycastParams.new()
        RayParams.FilterType = Enum.RaycastFilterType.Blacklist
        local Connections = { WalkSpeed = nil, NoClip = nil, GunAim = nil, AttackAim = nil, Stalk = nil, SkillHeartbeat = nil, CooldownBypass = nil, LeapBypass = nil, ESP = nil }
        local Attached = {}
        local hookedKillers = {}
        local VaultTracks = {}
        local ValidParryIds = {
            ["122812055447896"] = "Veil lunge", ["133963973694098"] = "Mayers Basic",
            ["117042998468241"] = "Mayers lunge", ["135002183282873"] = "cure lunge",
            ["121216847022485"] = "cure Basic", ["132817836308238"] = "Jeff Basic",
            ["129784271201071"] = "Jeff lunge", ["82666958311998"] = "Jeff Frenzy",
            ["78432063483146"] = "Abyssal Basic", ["118907603246885"] = "Abyssal lunge",
            ["139369275981139"] = "Jason Basic", ["110355011987939"] = "Jason lunge",
            ["111920872708571"] = "Masked Basic", ["105374834496520"] = "Masked lunge",
            ["138720291317243"] = "Masked Tony", ["106871536134254"] = "Masked Alex",
            ["130593238885843"] = "Masked Cobra", ["115244153053858"] = "Masked Cobra lunge",
            ["74968262036854"] = "Hidden Basic", ["113255068724446"] = "Hidden lunge",
            ["98163597193511"] = "Hidden S1", ["80411309607666"] = "Abyssal S1"
        }
        local KillerAnims = {
            ["rbxassetid://105374834496520"] = true, ["rbxassetid://113255068724446"] = true,
            ["rbxassetid://118907603246885"] = true, ["rbxassetid://129784271201071"] = true,
            ["rbxassetid://117042998468241"] = true, ["rbxassetid://122812055447896"] = true,
            ["rbxassetid://78935059863801"] = true, ["rbxassetid://74968262036854"] = true,
            ["rbxassetid://78432063483146"] = true, ["rbxassetid://132817836308238"] = true,
            ["rbxassetid://133963973694098"] = true, ["rbxassetid://111920872708571"] = true,
            ["rbxassetid://80411309607666"] = true, ["rbxassetid://98163597193511"] = true,
            ["rbxassetid://82666958311998"] = true, ["rbxassetid://110355011987939"] = true,
            ["rbxassetid://139369275981139"] = true, ["rbxassetid://135002183282873"] = true,
            ["rbxassetid://121216847022485"] = true, ["rbxassetid://130593238885843"] = true,
            ["rbxassetid://117070354890871"] = true, ["rbxassetid://106871536134254"] = true,
            ["rbxassetid://138720291317243"] = true
        }
        local AttackPaths = { "Slasher-mob.Controls.attack", "Masked-mob.Controls.attack", "Killer-mob.Controls.attack" }
        local ScreenEffectTypes = { "ColorCorrectionEffect", "DepthOfFieldEffect", "BlurEffect", "SunRaysEffect", "BloomEffect" }
        local PARRY_DEBOUNCE = 0.2
        local TouchID = 8822

        -- ========================================================================
        -- VARIABEL TAMBAHAN UNTUK AUTO SKILL CHECK MODE BARU
        -- ========================================================================
        local GenMode = "Instant"
        local GenEnabled = false
        local _lastGoalRot = 0
        local GenConnections = {}
        local _lastTriggerTick = 0

        -- ========================================================================
        -- FUNGSI ESP (diringkas agar tidak terlalu panjang)
        -- ========================================================================
        local function removeESP(obj)
            if not obj then return end
            local h = ESPCache.Objects[obj]
            if h then
                pcall(function() h:Destroy() end)
                ESPCache.Objects[obj] = nil
            end
        end

        local function createESP(obj, color)
            if not obj or not obj.Parent then return end
            local h = ESPCache.Objects[obj]
            if h and h.Parent then
                h.FillColor = color; h.OutlineColor = color; h.Enabled = true; return
            end
            pcall(function()
                h = Instance.new("Highlight")
                h.FillColor = color; h.OutlineColor = color; h.FillTransparency = 0.7; h.OutlineTransparency = 0.2
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee = obj; h.Parent = obj
                ESPCache.Objects[obj] = h
                obj.AncestryChanged:Connect(function(_, parent)
                    if not parent then ESPCache.Objects[obj] = nil end
                end)
            end)
        end

        local function GetHeldItem(char)
            if not char then return nil end
            for _, obj in ipairs(char:GetChildren()) do
                if ESPItems[obj.Name] then return obj.Name end
                if obj:IsA("Tool") and ESPItems[obj.Name] then return obj.Name end
            end
            return nil
        end

        local function ApplyGenHighlight(object, color)
            local h = object:FindFirstChild("GenHighlight") or Instance.new("Highlight")
            h.Name = "GenHighlight"; h.Adornee = object; h.FillColor = color; h.OutlineColor = color
            h.FillTransparency = 0.9; h.OutlineTransparency = 0.3; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = object
        end

        local function CreateBillboard(text, color)
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "GenESP"; billboard.Size = UDim2.new(0,100,0,30); billboard.AlwaysOnTop = true
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,0,1,0); label.BackgroundTransparency = 1; label.Text = text
            label.TextColor3 = color; label.TextStrokeTransparency = 0; label.Font = Enum.Font.GothamBold; label.TextSize = 12
            label.Parent = billboard
            return billboard
        end

        local function UpdateGenerator(generator)
            if not generator or not generator.Parent then return end
            if not ESP.Generator then
                local old = generator:FindFirstChild("GenESP"); if old then old:Destroy() end
                local h = generator:FindFirstChild("GenHighlight"); if h then h:Destroy() end
                return
            end
            local percent = GetGameValue(generator, "RepairProgress") or GetGameValue(generator, "Progress") or 0
            local billboard = generator:FindFirstChild("GenESP")
            if percent >= 100 then if billboard then billboard:Destroy() end; return end
            local cp = math.clamp(percent, 0, 100)
            local color = GeneratorColor:Lerp(Color3.fromRGB(0,255,120), cp / 100)
            local text = string.format("[%.0f%%]", percent)
            if not billboard then
                billboard = CreateBillboard(text, color); billboard.Adornee = generator; billboard.Parent = generator
            else
                local lbl = billboard:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.Text = text; lbl.TextColor3 = color end
            end
            ApplyGenHighlight(generator, color)
        end

        local function UpdateMapESP(obj, root)
            if not obj or not root then return end
            local pos
            if obj:IsA("Model") then pos = obj:GetPivot().Position
            elseif obj:IsA("BasePart") then pos = obj.Position end
            if not pos then return end
            local distance = (pos - root.Position).Magnitude
            if obj.Name == "Window" then
                if ESP.Window and distance <= ESP.Distance then createESP(obj, WindowColor)
                else removeESP(obj) end
            end
            if obj.Name == "Pallet" or obj.Name == "Palletwrong" then
                if ESP.Pallet and distance <= ESP.Distance then createESP(obj, PalletColor)
                else removeESP(obj) end
            end
        end

        local function UpdateSCPEsp(root)
            if not ESP.SCP then
                for obj in pairs(ESPCache.SCP) do removeESP(obj) end
                return
            end
            for obj in pairs(ESPCache.SCP) do
                if obj and obj.Parent then
                    local pos
                    if obj:IsA("Model") then pos = obj:GetPivot().Position
                    elseif obj:IsA("BasePart") then pos = obj.Position end
                    if pos then
                        if (pos - root.Position).Magnitude <= ESP.Distance then createESP(obj, SCPColor)
                        else removeESP(obj) end
                    end
                end
            end
        end

        local function removeStatusESP(char)
            if ESPCache.Status[char] then ESPCache.Status[char]:Destroy(); ESPCache.Status[char] = nil end
        end

        local function createStatusESP(player, char, root)
            if not ESPStatus.Enabled then removeStatusESP(char); return end
            if not root then return end
            local head = char:FindFirstChild("Head"); local hum = char:FindFirstChildOfClass("Humanoid")
            if not head or not hum then return end
            local isDown = hum.Health <= 0 or hum.Health < 2 or char:GetAttribute("Downed") == true or char:GetAttribute("IsDown") == true or char:GetAttribute("Knocked") == true
            local dist = (head.Position - root.Position).Magnitude
            if dist > ESPStatus.Radius then removeStatusESP(char); return end
            local text = ""
            if isDown then text = "ðŸ”» DOWN\n" end
            if ESPStatus.ShowName then
                text = text .. player.Name
                if ESPStatus.ShowItem then
                    local item = GetHeldItem(char)
                    if item then text = text .. " [" .. item .. "]" end
                end
                text = text .. "\n"
            end
            if ESPStatus.ShowDistance then text = text .. string.format("Dist: %.0f\n", dist) end
            if ESPStatus.ShowHealth then text = text .. string.format("HP: %.0f\n", hum.Health) end
            if text == "" then removeStatusESP(char); return end
            local teamColor = Color3.new(1,1,1)
            if player.Team then
                if player.Team.Name == "Killer" then teamColor = TeamColors.Killer
                elseif player.Team.Name == "Survivors" then teamColor = TeamColors.Survivor end
            end
            if isDown then teamColor = Color3.fromRGB(255,0,0) end
            local billboard = ESPCache.Status[char]
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Size = UDim2.new(0,120,0,50); billboard.AlwaysOnTop = true
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1,0,1,0); label.BackgroundTransparency = 1; label.TextColor3 = teamColor
                label.TextStrokeTransparency = 0; label.Font = Enum.Font.GothamBold; label.TextSize = 12
                label.Text = text; label.Parent = billboard
                billboard.Adornee = head; billboard.StudsOffset = Vector3.new(0,2.5,0); billboard.Parent = char
                ESPCache.Status[char] = billboard
            else
                local label = billboard:FindFirstChildOfClass("TextLabel")
                if label then label.Text = text; label.TextColor3 = teamColor end
            end
        end

        -- ========================================================================
        -- TELEPORT FUNCTIONS
        -- ========================================================================
        local function TeleportToPart(part)
            if not part then return end
            local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local offset = Vector3.new(0, 3, 0)
                if part:IsA("BasePart") then hrp.CFrame = part.CFrame + offset
                elseif part:IsA("Model") then
                    local p = part:FindFirstChildWhichIsA("BasePart")
                    if p then hrp.CFrame = p.CFrame + offset end
                end
                Oxidelib:Notify({ Title = "Teleport", Content = "Berhasil!", Duration = 1 })
            end
        end

        local function TeleportToGenerator()
            local gens = {}
            for obj in pairs(ESPCache.Generators) do if obj and obj.Parent then table.insert(gens, obj) end end
            if #gens == 0 then Oxidelib:Notify({ Title = "TP Generator", Content = "Tidak ada generator!", Duration = 2 }) return end
            if TeleportIndex.Generator > #gens then TeleportIndex.Generator = 1 end
            local gen = gens[TeleportIndex.Generator]
            local part = gen:FindFirstChildWhichIsA("BasePart")
            if part then TeleportToPart(part) end
            TeleportIndex.Generator = TeleportIndex.Generator + 1
        end

        local function TeleportToHook()
            local hooks = {}
            for _, obj in ipairs(workspace:GetDescendants()) do if obj.Name == "Hook" and obj:IsA("Model") then table.insert(hooks, obj) end end
            if #hooks == 0 then Oxidelib:Notify({ Title = "TP Hook", Content = "Tidak ada hook!", Duration = 2 }) return end
            if TeleportIndex.Hook > #hooks then TeleportIndex.Hook = 1 end
            local hook = hooks[TeleportIndex.Hook]
            local part = hook:FindFirstChild("HookPoint") or hook:FindFirstChildWhichIsA("BasePart")
            if part then TeleportToPart(part) end
            TeleportIndex.Hook = TeleportIndex.Hook + 1
        end

        local function TeleportToGate()
            local gates = {}
            for _, obj in ipairs(workspace:GetDescendants()) do if obj.Name == "Gate" and obj:IsA("Model") then table.insert(gates, obj) end end
            if #gates == 0 then Oxidelib:Notify({ Title = "TP Gate", Content = "Tidak ada gate!", Duration = 2 }) return end
            if TeleportIndex.Gate > #gates then TeleportIndex.Gate = 1 end
            local gate = gates[TeleportIndex.Gate]
            local part = gate:FindFirstChildWhichIsA("BasePart")
            if part then TeleportToPart(part) end
            TeleportIndex.Gate = TeleportIndex.Gate + 1
        end

        local function TeleportToPallet()
            local pallets = {}
            for pal in pairs(ESPCache.Pallets) do if pal and pal.Parent then table.insert(pallets, pal) end end
            if #pallets == 0 then Oxidelib:Notify({ Title = "TP Pallet", Content = "Tidak ada pallet!", Duration = 2 }) return end
            if TeleportIndex.Pallet > #pallets then TeleportIndex.Pallet = 1 end
            local pallet = pallets[TeleportIndex.Pallet]
            local part = pallet:FindFirstChild("PrimaryPartPallet") or pallet:FindFirstChildWhichIsA("BasePart")
            if part then TeleportToPart(part) end
            TeleportIndex.Pallet = TeleportIndex.Pallet + 1
        end

        local function TeleportToWindow()
            local windows = {}
            for win in pairs(ESPCache.Windows) do if win and win.Parent then table.insert(windows, win) end end
            if #windows == 0 then Oxidelib:Notify({ Title = "TP Window", Content = "Tidak ada window!", Duration = 2 }) return end
            if TeleportIndex.Window > #windows then TeleportIndex.Window = 1 end
            local window = windows[TeleportIndex.Window]
            local part = window:FindFirstChild("Bottom") or window:FindFirstChildWhichIsA("BasePart")
            if part then TeleportToPart(part) end
            TeleportIndex.Window = TeleportIndex.Window + 1
        end

        local function RefreshMapForTeleport()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Generator" then ESPCache.Generators[obj] = true
                elseif obj.Name == "Window" then ESPCache.Windows[obj] = true
                elseif obj.Name == "Pallet" or obj.Name == "Palletwrong" then ESPCache.Pallets[obj] = true
                elseif string.find(string.lower(obj.Name), "scp") then ESPCache.SCP[obj] = true
                end
            end
            TeleportIndex.Generator = 1; TeleportIndex.Hook = 1; TeleportIndex.Gate = 1; TeleportIndex.Pallet = 1; TeleportIndex.Window = 1
            Oxidelib:Notify({ Title = "Refresh Map", Content = "Cache diperbarui!", Duration = 2 })
        end

        RefreshMapForTeleport()

        workspace.DescendantAdded:Connect(function(obj)
            if obj.Name == "Generator" then ESPCache.Generators[obj] = true
            elseif obj.Name == "Pallet" or obj.Name == "Palletwrong" then ESPCache.Pallets[obj] = true
            elseif obj.Name == "Window" then ESPCache.Windows[obj] = true
            elseif string.find(string.lower(obj.Name), "scp") then ESPCache.SCP[obj] = true
            end
        end)
        workspace.DescendantRemoving:Connect(function(obj)
            ESPCache.Generators[obj] = nil; ESPCache.Pallets[obj] = nil; ESPCache.Windows[obj] = nil; ESPCache.SCP[obj] = nil
        end)

        local function teleportToFinishLine()
            local root = getRoot()
            if not root then return end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if string.lower(obj.Name) == "fininshline" and obj:IsA("BasePart") then
                    root.CFrame = obj.CFrame + Vector3.new(0,5,0); break
                end
            end
        end

        -- ========================================================================
        -- MOVEMENT FUNCTIONS
        -- ========================================================================
        local function applyWalkSpeed()
            if Connections.WalkSpeed then Connections.WalkSpeed:Disconnect() end
            Connections.WalkSpeed = RunService.Heartbeat:Connect(function()
                if not Movement.WalkSpeedEnabled then return end
                local char = LocalPlayer.Character; if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
                if hum.WalkSpeed ~= Movement.WalkSpeedValue then hum.WalkSpeed = Movement.WalkSpeedValue end
            end)
        end

        local function shouldDisableWalkSpeed()
            local char = LocalPlayer.Character; if not char then return false end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.Health <= 0 or hum.Health < 2 or char:GetAttribute("Downed") == true or char:GetAttribute("IsDown") == true or char:GetAttribute("Knocked") == true then
                    return true
                end
            end
            return false
        end

        local function applyJumpPower()
            if not Movement.JumpPowerEnabled then return end
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = Movement.JumpPowerValue end
        end

        local function toggleNoClip(state)
            Movement.NoClip = state
            if state then
                if Connections.NoClip then Connections.NoClip:Disconnect() end
                Connections.NoClip = RunService.RenderStepped:Connect(function()
                    if Movement.NoClip then
                        local char = LocalPlayer.Character
                        if char then
                            for _, v in pairs(char:GetDescendants()) do
                                if v:IsA("BasePart") then v.CanCollide = false end
                            end
                        end
                    end
                end)
            else
                if Connections.NoClip then Connections.NoClip:Disconnect(); Connections.NoClip = nil end
                local char = LocalPlayer.Character
                if char then
                    for _, v in pairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = true end
                    end
                end
            end
        end

        local function applyGodMode()
            if not PlayerMods.GodMode then return end
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            if hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Dead or s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
            end
        end

        -- ========================================================================
        -- PARRY FUNCTIONS
        -- ========================================================================
        function IsSafeToParry(char)
            if not Config.Surv_ParrySafety then return true end
            if not char then return false end
            local interactObj = char:FindFirstChild("CheckInterractable")
            if interactObj then
                if interactObj:GetAttribute("isVaulting") == true then return false end
                if interactObj:GetAttribute("isRepairing") == true then return false end
                if interactObj:GetAttribute("isUnhooking") == true then return false end
                if interactObj:GetAttribute("isHealing") == true then return false end
                if interactObj:GetAttribute("isSliding") == true then return false end
            end
            return true
        end

        function TriggerCrouch()
            pcall(function()
                local b = LocalPlayer:FindFirstChild("PlayerGui")
                for segment in string.gmatch("Survivor-mob.Controls.crouch.icon", "[^%.]+") do
                    if b then b = b:FindFirstChild(segment) end
                end
                if b and b:IsA("GuiObject") and b.Visible and b.Parent and b.Parent:IsA("GuiButton") then
                    local btn = b.Parent
                    if UserInputService.TouchEnabled and type(firesignal) == "function" then
                        firesignal(btn.MouseButton1Click)
                        task.wait(2)
                        firesignal(btn.MouseButton1Click)
                    else
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                        task.wait(2)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                    end
                else
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                    task.wait(2)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                end
            end)
        end

        function tapMobileParryButton()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then return end
            local survivorMob = playerGui:FindFirstChild("Survivor-mob")
            local parryBtn = survivorMob and survivorMob:FindFirstChild("Controls") and survivorMob.Controls:FindFirstChild("Gui-mob")
            if parryBtn and parryBtn.Visible then
                if firesignal then
                    pcall(function()
                        firesignal(parryBtn.MouseButton1Down)
                        task.wait(0.01)
                        firesignal(parryBtn.MouseButton1Up)
                    end)
                end
            else
                pcall(function()
                    if VirtualInputManager then
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                        task.wait(0.01)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    end
                end)
            end
        end

        function ExecuteParry()
            if State.ParryCooldown then return end
            pcall(function()
                local parryRemote = GetRemote("Remotes.Items.Parrying Dagger.parry")
                if parryRemote then
                    for i = 1, 10 do parryRemote:FireServer() end
                end
                task.spawn(tapMobileParryButton)
            end)
        end

        function ListenToParryResult()
            task.spawn(function()
                local parryResultRemote = GetRemote("Remotes.Items.Parrying Dagger.parryResult")
                if parryResultRemote then
                    parryResultRemote.OnClientEvent:Connect(function(arg1, arg2)
                        local cdDur = tonumber(arg2) or ((arg1 == true) and 90 or 60)
                        State.ParryCooldown = true
                        if State.ParryCooldownThread then task.cancel(State.ParryCooldownThread) end
                        State.ParryCooldownThread = task.delay(cdDur, function() State.ParryCooldown = false end)
                    end)
                end
            end)
        end
        ListenToParryResult()

        function AttachParrySensor(kChar)
            if not kChar or Attached[kChar] then return end
            Attached[kChar] = true
            local humanoid = kChar:FindFirstChild("Humanoid")
            if not humanoid then humanoid = kChar:WaitForChild("Humanoid", 5) end
            if not humanoid then return end
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then animator = humanoid:WaitForChild("Animator", 5) end
            if not animator then return end

            animator.AnimationPlayed:Connect(function(track)
                local animId = track.Animation and track.Animation.AnimationId or ""
                local id = animId:match("%d+")
                local attackName = ValidParryIds[id]
                if not attackName then return end
                
                if id == "80411309607666" and Config.Surv_AutoCrouch then
                    local myChar = LocalPlayer.Character
                    if IsDowned(myChar) then return end
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local kHRP = kChar:FindFirstChild("HumanoidRootPart")
                    if myHRP and kHRP then
                        local dist = (myHRP.Position - kHRP.Position).Magnitude
                        if dist <= 40 then TriggerCrouch() end
                    end
                    return
                end
                
                if not Config.Surv_AutoParry then return end
                if State.ParryCooldown then return end
                if Config.Ignored_Skills_List and Config.Ignored_Skills_List[attackName] then return end

                local myChar = LocalPlayer.Character
                if IsDowned(myChar) or not IsSafeToParry(myChar) then return end
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local kHRP = kChar:FindFirstChild("HumanoidRootPart")
                if not myHRP or not kHRP then return end
                
                local delta = myHRP.Position - kHRP.Position
                local startDistance = delta.Magnitude

                if Config.Surv_ParryAggressive then
                    local aggressiveRadius = 12
                    local detectionRadius = Config.Surv_ParryRadius + 5
                    if startDistance > detectionRadius then return end
                    if startDistance <= aggressiveRadius then ExecuteParry() else
                        local tracker
                        local startTime = os.clock()
                        tracker = RunService.Heartbeat:Connect(function()
                            if os.clock() - startTime >= 1.5 or State.ParryCooldown or not myHRP or not kHRP or IsDowned(myChar) then
                                if tracker then tracker:Disconnect() end
                                return
                            end
                            local currentDist = (myHRP.Position - kHRP.Position).Magnitude
                            if currentDist <= aggressiveRadius then ExecuteParry(); if tracker then tracker:Disconnect() end end
                        end)
                    end
                else
                    if startDistance > Config.Surv_ParryRadius then return end
                    local myPosFlat = Vector3.new(myHRP.Position.X, 0, myHRP.Position.Z)
                    local kPosFlat = Vector3.new(kHRP.Position.X, 0, kHRP.Position.Z)
                    local flatDelta = myPosFlat - kPosFlat
                    if flatDelta.Magnitude > 0 then
                        local flatDirection = flatDelta.Unit
                        local kLookFlat = Vector3.new(kHRP.CFrame.LookVector.X, 0, kHRP.CFrame.LookVector.Z).Unit
                        local isFacing = kLookFlat:Dot(flatDirection)
                        if isFacing < Config.Surv_ParryFace then return end
                    end
                    ExecuteParry()
                end
            end)
        end

        function TryAttach(p)
            if p ~= LocalPlayer and IsKiller(p) and p.Character then AttachParrySensor(p.Character) end
        end

        function SetupPlayer(p)
            if p == LocalPlayer then return end
            p.CharacterAdded:Connect(function() TryAttach(p) end)
            p:GetPropertyChangedSignal("Team"):Connect(function() TryAttach(p) end)
            if p.Character then TryAttach(p) end
        end

        -- ========================================================================
        -- FAKE PARRY
        -- ========================================================================
        local function CreateFakeParryButton()
            if State.FakeParryButton then State.FakeParryButton:Destroy() end
            local gui = Instance.new("ScreenGui")
            gui.Name = "FakeParryGui"; gui.ResetOnSpawn = false; gui.Parent = PlayerGui
            local btn = Instance.new("ImageButton")
            btn.Size = UDim2.new(0,50,0,50); btn.Position = UDim2.new(0.65,0,0.60,0)
            btn.BackgroundColor3 = Color3.fromRGB(255,255,255); btn.BackgroundTransparency = 0.9
            btn.Image = "rbxassetid://73705354917255"; btn.ImageTransparency = 0.1; btn.Parent = gui
            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = btn
            local stroke = Instance.new("UIStroke"); stroke.Thickness = 1.2; stroke.Color = Color3.fromRGB(255,255,255); stroke.Transparency = 0.8; stroke.Parent = btn
            btn.MouseButton1Click:Connect(function() if FakeParry.Enabled then PlayFakeParry() end end)
            State.FakeParryButton = gui
        end

        local function RemoveFakeParryButton()
            if State.FakeParryButton then State.FakeParryButton:Destroy(); State.FakeParryButton = nil end
        end

        local function PlayFakeParry()
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            if State.FakeParryTrack then State.FakeParryTrack:Stop(); State.FakeParryTrack = nil end
            local anim = Instance.new("Animation")
            anim.AnimationId = FakeParryAnimations[FakeParry.Animation]
            State.FakeParryTrack = animator:LoadAnimation(anim)
            State.FakeParryTrack.Priority = Enum.AnimationPriority.Action
            State.FakeParryTrack:Play()
        end

        -- ========================================================================
        -- AUTO SKILL CHECK
        -- ========================================================================
        local function GetSkillCheck()
            if not PlayerGui then return nil, nil end
            local LINE_NAMES = {"Line","Needle","Pointer","Indicator","Arrow"}
            local GOAL_NAMES = {"Goal","Zone","Bar","Target","SuccessZone","PerfectZone"}
            local function isVisible(obj) return obj:IsA("GuiObject") and obj.Visible ~= false end
            local function findNamed(root, names)
                for _, nm in ipairs(names) do
                    local f = root:FindFirstChild(nm, true)
                    if f and isVisible(f) then return f end
                end
                return nil
            end
            for _, gui in ipairs(PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    local line = findNamed(gui, LINE_NAMES)
                    local goal = findNamed(gui, GOAL_NAMES)
                    if line and goal then return line, goal end
                end
            end
            return nil, nil
        end

        local function GetGoalHalfWidth(goal)
            local width = 10
            pcall(function()
                if goal:IsA("GuiObject") and goal.AbsoluteSize and goal.AbsoluteSize.X > 0 then
                    local sizeScale = goal.Size.X.Scale
                    if sizeScale > 0 and sizeScale < 1 then
                        width = sizeScale * 360 * 0.5
                    end
                end
            end)
            return math.clamp(width, 4, 40)
        end

        local function FindActionButton()
            local function search(parent)
                for _, child in ipairs(parent:GetChildren()) do
                    if child.Name == "check" or child.Name == "Check" then return child end
                    local found = search(child)
                    if found then return found end
                end
                return nil
            end
            return search(PlayerGui)
        end

        local function PressActionNow()
            if tick() - _lastTriggerTick < 0.08 then return end
            _lastTriggerTick = tick()
            if IsMobile() then
                local btn = FindActionButton()
                if btn and btn:IsA("GuiObject") then
                    local p, s, ins = btn.AbsolutePosition, btn.AbsoluteSize, GuiService:GetGuiInset()
                    local cx = p.X + s.X/2 + ins.X; local cy = p.Y + s.Y/2 + ins.Y
                    pcall(function()
                        VirtualInputManager:SendTouchEvent(TouchID, 0, cx, cy)
                        task.wait(0.005)
                        VirtualInputManager:SendTouchEvent(TouchID, 2, cx, cy)
                    end)
                end
            else
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.005)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.005)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end)
            end
        end

        local function StopGenerator()
            for _, con in ipairs(GenConnections) do pcall(con.Disconnect, con) end
            table.clear(GenConnections)
        end

        local function StartGenerator()
            StopGenerator()
            if not GenEnabled then return end
            local heartbeat = RunService.Heartbeat:Connect(function()
                if not GenEnabled then StopGenerator(); return end
                local line, goal = GetSkillCheck()
                if not line or not goal then return end
                if GenMode == "Instant" then PressActionNow(); return end
                local lr = (line.Rotation or 0) % 360
                local gr = (goal.Rotation or 0) % 360
                local goalVelocity = math.abs(gr - _lastGoalRot)
                _lastGoalRot = gr
                local halfWidth = GetGoalHalfWidth(goal)
                local dynamicOffset = math.clamp(goalVelocity * 0.25, 0, halfWidth * 0.4)
                local perfectStart = (gr - halfWidth - dynamicOffset) % 360
                local perfectEnd   = (gr + halfWidth + dynamicOffset) % 360
                local neutralStart = (gr - halfWidth * 2.4 - dynamicOffset) % 360
                local neutralEnd   = (gr + halfWidth * 2.4 + dynamicOffset) % 360
                local function within(val, s, e)
                    if s > e then return (val >= s or val <= e) end
                    return (val >= s and val <= e)
                end
                local shouldPress = false
                if GenMode == "Legit" then
                    shouldPress = within(lr, perfectStart, perfectEnd)
                elseif GenMode == "Random" then
                    if math.random(1, 10) <= 7 then
                        shouldPress = within(lr, perfectStart, perfectEnd)
                    else
                        shouldPress = within(lr, neutralStart, neutralEnd) and not within(lr, perfectStart, perfectEnd)
                    end
                end
                if shouldPress then PressActionNow() end
            end)
            table.insert(GenConnections, heartbeat)
        end

        -- ========================================================================
        -- EMOTE FUNCTIONS
        -- ========================================================================
        local function playEmote(name) pcall(function() EmoteRemote:FireServer(name) end) end
        local function createEmoteButton()
            if EmoteButton.GuiInstance then EmoteButton.GuiInstance:Destroy() end
            local gui = Instance.new("ScreenGui")
            gui.Name = "EmoteButtonGui"; gui.ResetOnSpawn = false; gui.Parent = PlayerGui
            local btn = Instance.new("ImageButton")
            btn.Size = UDim2.new(0,50,0,50); btn.Position = UDim2.new(0.55,0,0.75,0)
            btn.BackgroundColor3 = Color3.fromRGB(255,255,255); btn.BackgroundTransparency = 0.9
            btn.Image = "rbxassetid://87624947008823"; btn.ImageTransparency = 0.1; btn.Parent = gui
            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = btn
            local stroke = Instance.new("UIStroke"); stroke.Thickness = 1.2; stroke.Color = Color3.fromRGB(255,255,255); stroke.Transparency = 0.8; stroke.Parent = btn
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0,80,0,20); label.Position = UDim2.new(0.5,-40,-0.6,0)
            label.BackgroundTransparency = 1; label.Text = Emote.Selected
            label.TextColor3 = Color3.fromRGB(255,255,255); label.TextStrokeTransparency = 0.5
            label.Font = Enum.Font.GothamBold; label.TextSize = 11; label.Parent = btn
            btn.MouseButton1Click:Connect(function() playEmote(Emote.Selected) end)
            EmoteButton.GuiInstance = gui
        end
        local function removeEmoteButton()
            if EmoteButton.GuiInstance then EmoteButton.GuiInstance:Destroy(); EmoteButton.GuiInstance = nil end
        end

        -- ========================================================================
        -- GUN AIM
        -- ========================================================================
        local function isVisible(part)
            RayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            local cam = workspace.CurrentCamera
            local origin = cam.CFrame.Position
            local direction = part.Position - origin
            local result = workspace:Raycast(origin, direction, RayParams)
            if not result then return true end
            return result.Instance:IsDescendantOf(part.Parent)
        end

        local function getClosestGunTarget()
            local cam = workspace.CurrentCamera
            local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            local closest, shortest = nil, GunAim.FOV
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Team then
                    local valid = (GunAim.TargetMode == "Killer" and p.Team.Name == "Killer") or (GunAim.TargetMode == "Survivor" and p.Team.Name == "Survivors")
                    if valid then
                        local hrp = p.Character:FindFirstChild(GunAim.AimPart)
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local pos, visible = cam:WorldToViewportPoint(hrp.Position)
                            if visible then
                                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                                if dist < shortest then
                                    if GunAim.VisibilityCheck and not isVisible(hrp) then continue end
                                    shortest = dist; closest = hrp
                                end
                            end
                        end
                    end
                end
            end
            if GunAim.TargetMode == "SCP" then
                for obj in pairs(ESPCache.SCP) do
                    if obj and obj.Parent then
                        local part
                        if obj:IsA("Model") then part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        elseif obj:IsA("BasePart") then part = obj end
                        if part then
                            local pos, visible = cam:WorldToViewportPoint(part.Position)
                            if visible then
                                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                                if dist < shortest then shortest = dist; closest = part end
                            end
                        end
                    end
                end
            end
            return closest
        end

        function startGunAim()
            if Connections.GunAim then Connections.GunAim:Disconnect() end
            Connections.GunAim = RunService.RenderStepped:Connect(function()
                if not GunAim.Enabled then return end
                if not GunAim.Holding then return end
                local cam = workspace.CurrentCamera
                local target = getClosestGunTarget()
                if not target then return end
                local pos = target.Position
                if GunAim.Predict then pos = pos + (target.AssemblyLinearVelocity * GunAim.PredictStrength) end
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, pos), GunAim.Strength)
            end)
        end

        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then GunAim.Holding = true end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then GunAim.Holding = false end
        end)

        -- ========================================================================
        -- KILLER FUNCTIONS
        -- ========================================================================
        local function StartLeapBypass()
            Connections.LeapBypass = task.spawn(function()
                local leapFunction, m2Function
                for _, v in pairs(getgc(true)) do
                    if type(v) == "function" and islclosure(v) then
                        local info = debug.getinfo(v)
                        if info.name == "tryActivate" then leapFunction = v end
                        if info.name == "playM2Animation" then m2Function = v end
                        if leapFunction and m2Function then break end
                    end
                end
                if not leapFunction and not m2Function then warn("Function tidak ditemukan.") return end
                while task.wait(0.1) do
                    if not Killer.BypassLeap then break end
                    for _, fn in pairs({leapFunction, m2Function}) do
                        if fn then
                            for i, val in pairs(debug.getupvalues(fn)) do
                                if type(val) == "boolean" and val == true then debug.setupvalue(fn, i, false) end
                            end
                        end
                    end
                end
            end)
        end

        local function StartCooldownBypass()
            if not State.CorruptHandlerFunc then
                for _, v in pairs(getgc(true)) do
                    if type(v) == "function" and islclosure(v) then
                        local constants = debug.getconstants(v)
                        if table.find(constants, "corrupt") and table.find(constants, "Immobile") then
                            State.CorruptHandlerFunc = v
                            break
                        end
                    end
                end
            end
            if not State.CorruptHandlerFunc then warn("Fungsi corruptHandler tidak ditemukan di memori.") return end
            if Connections.CooldownBypass then Connections.CooldownBypass:Disconnect() end
            Connections.CooldownBypass = RunService.Heartbeat:Connect(function()
                if not Killer.BypassCooldown then return end
                if State.CorruptHandlerFunc then
                    local upvalues = debug.getupvalues(State.CorruptHandlerFunc)
                    for idx, val in pairs(upvalues) do
                        if type(val) == "boolean" then
                            if val == false then debug.setupvalue(State.CorruptHandlerFunc, idx, true) end
                        end
                    end
                end
            end)
        end

        local function StopCooldownBypass()
            if Connections.CooldownBypass then Connections.CooldownBypass:Disconnect(); Connections.CooldownBypass = nil end
        end

        local function GetNearestKiller()
            local root = getRoot()
            if not root then return nil, math.huge end
            local closest, shortest = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Killer" and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < shortest then shortest = dist; closest = hrp end
                    end
                end
            end
            return closest, shortest
        end

        local function GetNearestAliveSurvivor()
            local root = getRoot()
            if not root then return nil end
            local closest, shortest = nil, math.huge
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 30 then
                        local d = (hrp.Position - root.Position).Magnitude
                        if d < shortest then shortest = d; closest = plr.Character end
                    end
                end
            end
            return closest
        end

        local function startAutoStalk()
            if Connections.Stalk then return end
            Connections.Stalk = RunService.Heartbeat:Connect(function()
                if not AutoStalk.Enabled then return end
                local root = getRoot()
                if not root then return end
                local closest, shortest = nil, math.huge
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 30 then
                            local dist = (hrp.Position - root.Position).Magnitude
                            if dist <= AutoStalk.StalkRange and dist < shortest then
                                shortest = dist; closest = plr
                            end
                        end
                    end
                end
                if closest then
                    local stalkEvent = GetRemote("Remotes.Killers.Stalker.StartStalking")
                    if stalkEvent then pcall(function() stalkEvent:FireServer(closest) end) end
                end
            end)
        end

        local function stopAutoStalk()
            if Connections.Stalk then Connections.Stalk:Disconnect(); Connections.Stalk = nil end
        end

        local function startAttackAim()
            if Connections.AttackAim then return end
            Connections.AttackAim = RunService.RenderStepped:Connect(function()
                if not AttackAim.Enabled then return end
                if not AttackAim.Holding then return end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                local closest, shortest = nil, AttackAim.FOV
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
                        local hrp = p.Character:FindFirstChild(AttackAim.AimPart)
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local pos, visible = cam:WorldToViewportPoint(hrp.Position)
                            if visible then
                                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                                if dist < shortest then shortest = dist; closest = hrp end
                            end
                        end
                    end
                end
                if closest then
                    local pos = closest.Position
                    if AttackAim.Predict then pos = pos + (closest.AssemblyLinearVelocity * AttackAim.PredictStrength) end
                    cam.CFrame = CFrame.new(cam.CFrame.Position, pos)
                end
            end)
        end

        -- ========================================================================
        -- AUTO PALLET
        -- ========================================================================
        local function HandleAutoPallet()
            if not Auto.PalletDrop then return end
            local plr = LocalPlayer
            if not (plr.Team and plr.Team.Name == "Survivors") then return end
            local now = tick()
            if now - Timers.lastPalletScan < 0.2 then return end
            Timers.lastPalletScan = now
            if now - Timers.lastPalletDrop < 2.5 then return end
            local root = getRoot()
            if not root then return end
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            local killerRoot, killerDist = GetNearestKiller()
            if not killerRoot or killerDist > Auto.PalletDropDist then return end
            local dropEvent = GetRemote("Remotes.Pallet.PalletDropEvent")
            if not dropEvent then return end
            local bestPallet = nil; local bestDist = 8
            for pal in pairs(ESPCache.Pallets) do
                if not pal or State.UsedPallets[pal] then continue end
                local refPart = pal:FindFirstChild("PalletPoint") or pal:FindFirstChild("PalletPointSlide")
                if not refPart then continue end
                local ok, pos = pcall(function() return refPart.Position end)
                if not ok or not pos then continue end
                local d = (root.Position - pos).Magnitude
                if d < bestDist then bestDist = d; bestPallet = pal end
            end
            if bestPallet then
                local fireTarget = bestPallet:FindFirstChild("PalletPointSlide") or bestPallet:FindFirstChild("PalletPoint")
                if fireTarget then
                    pcall(function() dropEvent:FireServer(fireTarget) end)
                    State.UsedPallets[bestPallet] = true
                    Timers.lastPalletDrop = now
                end
            end
        end

        -- ========================================================================
        -- BLOCK VAULTS
        -- ========================================================================
        local function HandleBlockVaults()
            if not Killer.BlockVaults then return end
            local vaultEvent = GetRemote("Remotes.Window.VaultEvent")
            if not vaultEvent then return end
            local map = workspace:FindFirstChild("Map")
            local vaultsFolder = map and map:FindFirstChild("Vaults")
            if vaultsFolder then
                for _, vault in ipairs(vaultsFolder:GetChildren()) do
                    for _, part in ipairs(vault:GetChildren()) do
                        if part:IsA("BasePart") then
                            pcall(function() vaultEvent:FireServer(part, true) end)
                        end
                    end
                end
            else
                for window in pairs(ESPCache.Windows) do
                    if window and window.Parent then
                        for _, child in ipairs(window:GetDescendants()) do
                            if child:IsA("BasePart") then
                                pcall(function() vaultEvent:FireServer(child, true) end)
                            end
                        end
                    end
                end
            end
        end

        -- ========================================================================
        -- FAST VAULT
        -- ========================================================================
        local function normalizeId(id)
            local num = tostring(id):match("%d+")
            return num and ("rbxassetid://" .. num)
        end

        local function hookVault(char)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then return end
            animator.AnimationPlayed:Connect(function(track)
                if not FastVault.Enabled then return end
                local anim = track.Animation
                if not anim or not anim.AnimationId then return end
                local id = normalizeId(anim.AnimationId)
                if not id then return end
                local replaceId = FastVault.ReplaceMap[id]
                if not replaceId then return end
                if VaultTracks[track] then return end
                VaultTracks[track] = true
                track:Stop()
                local newAnim = Instance.new("Animation"); newAnim.AnimationId = replaceId
                local newTrack = animator:LoadAnimation(newAnim)
                newTrack.Priority = Enum.AnimationPriority.Action
                newTrack:Play(); newTrack:AdjustSpeed(FastVault.Speed)
                newTrack.Stopped:Connect(function() VaultTracks[track] = nil end)
                if FastVaultRemote then pcall(function() FastVaultRemote:FireServer(LocalPlayer) end) end
            end)
        end

        -- ========================================================================
        -- VISUAL FUNCTIONS
        -- ========================================================================
        local function applyVisual()
            if Visual.Fullbright then
                Lighting.Brightness = 2; Lighting.ClockTime = 14
                Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
            else
                Lighting.Brightness = OriginalLighting.Brightness
                Lighting.ClockTime = OriginalLighting.ClockTime
                Lighting.Ambient = OriginalLighting.Ambient
                Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
            end
            Lighting.GlobalShadows = not Visual.NoShadow
            if Visual.Ambient then
                Lighting.Ambient = Visual.AmbientColor
                Lighting.OutdoorAmbient = Visual.AmbientColor
                Lighting.Brightness = Visual.Brightness
                Lighting.ClockTime = Visual.ClockTime
            elseif not Visual.Fullbright then
                Lighting.Brightness = OriginalLighting.Brightness
                Lighting.ClockTime = OriginalLighting.ClockTime
                Lighting.Ambient = OriginalLighting.Ambient
                Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
            end
        end

        local function applyOptimization()
            pcall(function()
                settings().Rendering.QualityLevel = Visual.LowGraphics and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
            end)
            if Visual.CleanSky then
                for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
            end
        end

        local function applyNoScreenEffects()
            if Visual.NoScreenEffects then
                for _, v in pairs(Lighting:GetChildren()) do
                    for _, t in pairs(ScreenEffectTypes) do
                        if v:IsA(t) then DisabledEffects[v] = v.Enabled; v.Enabled = false end
                    end
                end
            else
                for obj, s in pairs(DisabledEffects) do if obj and obj.Parent then obj.Enabled = s end end
                DisabledEffects = {}
            end
        end

        local function applyUnlimitedZoom()
            if CameraZoom.UnlimitedZoom then
                LocalPlayer.CameraMaxZoomDistance = CameraZoom.MaxDistance
                LocalPlayer.CameraMinZoomDistance = CameraZoom.MinDistance
            else
                LocalPlayer.CameraMaxZoomDistance = 128
                LocalPlayer.CameraMinZoomDistance = 0.5
            end
        end

        local function applyCameraFOV()
            local cam = workspace.CurrentCamera
            if not cam then return end
            cam.FieldOfView = CameraZoom.FOVEnabled and CameraZoom.FOV or CameraZoom.DefaultFOV
        end

        local function UpdateThirdPerson()
            local cam = workspace.CurrentCamera
            if not cam then return end
            local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
            local shouldBeActive = Killer.ThirdPerson and isKiller
            if shouldBeActive then
                if not Killer.ThirdPersonWasActive then Killer.OriginalCameraType = cam.CameraType end
                cam.CameraType = Enum.CameraType.Custom
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.CameraOffset = Vector3.new(2,1,8) end
                Killer.ThirdPersonWasActive = true
            elseif Killer.ThirdPersonWasActive then
                if Killer.OriginalCameraType then cam.CameraType = Killer.OriginalCameraType; Killer.OriginalCameraType = nil end
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.CameraOffset = Vector3.new(0,0,0) end
                Killer.ThirdPersonWasActive = false
            end
        end

        local function updateParryCircle()
            local root = getRoot()
            if not ParryRangeVisual.Enabled or not root then
                if State.ParryCircle then State.ParryCircle:Destroy(); State.ParryCircle = nil end
                return
            end
            if not State.ParryCircle then
                State.ParryCircle = Instance.new("CylinderHandleAdornment")
                State.ParryCircle.Name = "ParryRangeCircle"
                State.ParryCircle.Height = 0.05
                State.ParryCircle.Transparency = 0.3
                State.ParryCircle.AlwaysOnTop = false
                State.ParryCircle.ZIndex = 0
                State.ParryCircle.Adornee = root
                State.ParryCircle.Parent = root
            end
            local radius = Auto.ParryDistance
            State.ParryCircle.Radius = radius
            State.ParryCircle.InnerRadius = math.max(0.1, radius - 0.15)
            State.ParryCircle.CFrame = CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
            State.ParryCircle.Color3 = ParryRangeVisual.Color
        end

        local function clearCrosshair()
            for _, v in pairs(CrosshairDrawings) do if v.Remove then v:Remove() end end
            CrosshairDrawings = {}
        end

        local function drawCrosshair()
            if not Crosshair.Enabled then
                for _, v in pairs(CrosshairDrawings) do if v then v.Visible = false end end
                return
            end
            if State.LastCrosshairStyle ~= Crosshair.Style then
                clearCrosshair(); State.created = false
                State.LastCrosshairStyle = Crosshair.Style
            end
            local cam = workspace.CurrentCamera
            local center = Vector2.new(cam.ViewportSize.X / 2 + Crosshair.OffsetX, cam.ViewportSize.Y / 2 + Crosshair.OffsetY)
            if not State.created then
                State.created = true
                if Crosshair.Style == "Plus" then
                    for i = 1, 4 do
                        local line = Drawing.new("Line"); line.Visible = true
                        table.insert(CrosshairDrawings, line)
                    end
                elseif Crosshair.Style == "Dot" then
                    local dot = Drawing.new("Circle"); dot.Filled = true; dot.Visible = true
                    table.insert(CrosshairDrawings, dot)
                elseif Crosshair.Style == "Circle" then
                    local circle = Drawing.new("Circle"); circle.Filled = false; circle.Visible = true
                    table.insert(CrosshairDrawings, circle)
                end
            end
            if Crosshair.Style == "Plus" then
                for _, line in pairs(CrosshairDrawings) do line.Color = Crosshair.Color; line.Thickness = Crosshair.Thickness end
                CrosshairDrawings[1].From = center + Vector2.new(-Crosshair.Size, 0); CrosshairDrawings[1].To = center + Vector2.new(-2, 0)
                CrosshairDrawings[2].From = center + Vector2.new(Crosshair.Size, 0); CrosshairDrawings[2].To = center + Vector2.new(2, 0)
                CrosshairDrawings[3].From = center + Vector2.new(0, -Crosshair.Size); CrosshairDrawings[3].To = center + Vector2.new(0, -2)
                CrosshairDrawings[4].From = center + Vector2.new(0, Crosshair.Size); CrosshairDrawings[4].To = center + Vector2.new(0, 2)
            elseif Crosshair.Style == "Dot" then
                local dot = CrosshairDrawings[1]
                dot.Position = center; dot.Radius = Crosshair.Size / 2; dot.Color = Crosshair.Color
            elseif Crosshair.Style == "Circle" then
                local circle = CrosshairDrawings[1]
                circle.Position = center; circle.Radius = Crosshair.Size
                circle.Color = Crosshair.Color; circle.Thickness = Crosshair.Thickness
            end
        end

        -- ========================================================================
        -- KORLESS MORPH
        -- ========================================================================
        local KorlessMorph = {}
        local function ApplyKorless()
            local plr = LocalPlayer
            local function Morph()
                repeat task.wait() until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Right Leg")
                task.wait(0.1)
                local char = plr.Character
                pcall(function()
                    char.Head.Transparency = 1
                    local face = char.Head:FindFirstChild("face")
                    if face then face:Destroy() end
                    char["Right Leg"].Transparency = 1
                    local mesh = Instance.new("MeshPart")
                    mesh.Name = "KorlessHead"
                    mesh.Size = Vector3.new(1.5,1.5,1.5)
                    mesh.CanCollide = false
                    mesh.MeshId = "rbxassetid://902942096"
                    mesh.TextureID = "rbxassetid://902843398"
                    mesh.CFrame = char["Right Leg"].CFrame * CFrame.new(0,0.5,0)
                    mesh.Parent = char
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = char["Right Leg"]
                    weld.Part1 = mesh
                    weld.Parent = mesh
                end)
            end
            Morph()
            if KorlessMorph.Connection then KorlessMorph.Connection:Disconnect() end
            KorlessMorph.Connection = plr.CharacterAdded:Connect(function() task.wait(1); Morph() end)
            Oxidelib:Notify({ Title = "WISNU", Content = "Korless Morph Applied", Duration = 3 })
        end

        -- ========================================================================
        -- FAKE TAG
        -- ========================================================================
        TextChatService.OnIncomingMessage = function(message)
            local props = Instance.new("TextChatMessageProperties")
            if FakeTag.Enabled and message.TextSource then
                if message.TextSource.UserId == LocalPlayer.UserId then
                    props.PrefixText = string.format(
                        "<font color=\"%s\"><b>%s</b></font> %s",
                        FakeTag.Color,
                        FakeTag.Text,
                        message.PrefixText
                    )
                end
            end
            return props
        end

        -- ========================================================================
        -- GEN BYPASS
        -- ========================================================================
        function GB_GetAllGenerators()
            local now = tick()
            if now - GenBypass.CacheTimer < 5 then return GenBypass.Cache end
            GenBypass.Cache = {}
            GenBypass.CacheTimer = now
            local mapFolder = workspace:FindFirstChild("Map")
            if not mapFolder then return GenBypass.Cache end
            pcall(function()
                for _, v in pairs(mapFolder:GetDescendants()) do
                    if not v:IsA("Model") then continue end
                    if v.Name ~= "Generator" then continue end
                    local isReal = v:GetAttribute("RepairProgress") ~= nil or v:GetAttribute("kickcount") ~= nil or v:GetAttribute("ProgressRepair") ~= nil
                    if isReal then table.insert(GenBypass.Cache, v) end
                end
            end)
            return GenBypass.Cache
        end

        function GB_GetPoints(genModel)
            local points = {}
            pcall(function()
                for _, obj in pairs(genModel:GetChildren()) do
                    if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then table.insert(points, obj) end
                end
            end)
            return points
        end

        function GB_WaitRepairing(point, timeout)
            local start = tick()
            while tick() - start < (timeout or 1) do
                if point:GetAttribute("IsRepairing") == true then return true end
                task.wait(0.05)
            end
            return false
        end

        function GB_DoRepair(targetPoint)
            local genModel = targetPoint.Parent
            if GenBypass.Processed[genModel] then return end
            GenBypass.Processed[genModel] = true
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then GenBypass.Processed[genModel] = nil return end
            local RepairEvent = GetRemote("Remotes.Generator.RepairEvent")
            if not RepairEvent then GenBypass.Processed[genModel] = nil return end
            local originalCFrame = hrp.CFrame
            pcall(function()
                for _, point in pairs(GB_GetPoints(genModel)) do
                    if point ~= targetPoint and point.Parent then
                        hrp.Anchored = true
                        hrp.CFrame = point.CFrame
                        task.wait(0.15)
                        pcall(function() RepairEvent:FireServer(point, true) end)
                        if not GB_WaitRepairing(point, 0.8) then
                            pcall(function() RepairEvent:FireServer(point, false) end)
                            task.wait(0.1)
                            hrp.CFrame = point.CFrame
                            task.wait(0.15)
                            pcall(function() RepairEvent:FireServer(point, true) end)
                            GB_WaitRepairing(point, 0.5)
                        end
                        hrp.Anchored = false
                        task.wait(0.05)
                    end
                end
            end)
            pcall(function()
                if hrp and hrp.Parent then
                    hrp.Anchored = false
                    hrp.CFrame = originalCFrame
                end
            end)
            task.wait(0.1)
            pcall(function() RepairEvent:FireServer(targetPoint, false) end)
            GenBypass.Processed[genModel] = nil
        end

        function GB_GetNearestPoint()
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end
            local bestPoint, bestDist = nil, math.huge
            for _, gen in pairs(GB_GetAllGenerators()) do
                for _, point in pairs(GB_GetPoints(gen)) do
                    local d = (hrp.Position - point.Position).Magnitude
                    if d < bestDist then bestDist = d; bestPoint = point end
                end
            end
            return bestPoint, bestDist
        end

        function GB_UpdateButton()
            if GenBypass.Button then GenBypass.Button.Visible = GenBypass.Enabled and IsMobile() end
        end

        function GB_CreateButton()
            local oldUI = PlayerGui:FindFirstChild("BypassGenUI")
            if oldUI then oldUI:Destroy() end
            GenBypass.UI = Instance.new("ScreenGui")
            GenBypass.UI.Name = "BypassGenUI"
            GenBypass.UI.ResetOnSpawn = false
            GenBypass.UI.IgnoreGuiInset = true
            GenBypass.UI.Parent = PlayerGui
            GenBypass.Button = Instance.new("ImageButton")
            GenBypass.Button.Name = "BypassGenButton"
            GenBypass.Button.Size = UDim2.new(0,60,0,60)
            GenBypass.Button.Position = UDim2.new(0.88,0,0.55,0)
            GenBypass.Button.AnchorPoint = Vector2.new(0.5,0.5)
            GenBypass.Button.BackgroundColor3 = Color3.fromRGB(255,255,255)
            GenBypass.Button.BackgroundTransparency = 0.15
            GenBypass.Button.AutoButtonColor = true
            GenBypass.Button.Visible = false
            GenBypass.Button.ZIndex = 10
            GenBypass.Button.Parent = GenBypass.UI
            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = GenBypass.Button
            local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255,255,255); stroke.Thickness = 2; stroke.Transparency = 0.2; stroke.Parent = GenBypass.Button
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "BYPASS"
            lbl.TextColor3 = Color3.fromRGB(255,255,255)
            lbl.TextScaled = true
            lbl.Font = Enum.Font.GothamBlack
            lbl.ZIndex = 11
            lbl.Parent = GenBypass.Button
            GenBypass.Button.MouseButton1Click:Connect(function()
                if not GenBypass.Enabled then return end
                local bestPoint, bestDist = GB_GetNearestPoint()
                if bestPoint and bestDist <= 8 then GB_DoRepair(bestPoint) end
            end)
        end

        GB_CreateButton()
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            GB_CreateButton()
            GB_UpdateButton()
        end)

        local function setGenBypass(v)
            GenBypass.Enabled = v
            GB_UpdateButton()
            if v then Oxidelib:Notify({ Title = "Gen Bypass", Content = "Diaktifkan - Klik tombol BYPASS di layar", Duration = 3 }) end
        end

        -- ========================================================================
        -- MOONWALK
        -- ========================================================================
        local CONFIG_MW = { SIDE_SPEED = 2.2, BACK_SPEED = 4.0, INTERVAL = 0.045, SMOOTH_FACTOR = 0.85, KEYBIND = Enum.KeyCode.G, GUI_POSITION = UDim2.fromScale(0.78,0.22), AUTO_START = false }
        local MoonwalkEnabled = false
        local MoonwalkMoveConn = nil
        local MoonwalkGui = nil
        local KeybindConn = nil
        local CharAddedConn = nil
        local CurrentDirection = 1
        local LastSwitch = 0
        local SmoothVelocity = Vector3.new()

        local function stopMoonwalkInternal()
            if MoonwalkMoveConn then MoonwalkMoveConn:Disconnect(); MoonwalkMoveConn = nil end
            SmoothVelocity = Vector3.new()
        end

        local function destroyMoonwalkGui()
            if MoonwalkGui then MoonwalkGui:Destroy(); MoonwalkGui = nil end
        end

        local function startMoonwalkInternal()
            stopMoonwalkInternal()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end
            CurrentDirection = 1
            LastSwitch = 0
            MoonwalkMoveConn = RunService.RenderStepped:Connect(function(deltaTime)
                if not MoonwalkEnabled then return end
                local currentChar = LocalPlayer.Character
                if not currentChar then return end
                local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
                local currentHum = currentChar:FindFirstChildOfClass("Humanoid")
                if not currentHrp or not currentHum or currentHum.Health <= 0 then stopMoonwalkInternal(); return end
                local now = tick()
                if now - LastSwitch >= CONFIG_MW.INTERVAL then
                    CurrentDirection = CurrentDirection * -1
                    LastSwitch = now
                end
                local lookVector = currentHrp.CFrame.LookVector
                local rightVector = currentHrp.CFrame.RightVector
                local targetVelocity = (lookVector * -CONFIG_MW.BACK_SPEED) + (rightVector * (CurrentDirection * CONFIG_MW.SIDE_SPEED))
                SmoothVelocity = SmoothVelocity:Lerp(targetVelocity, CONFIG_MW.SMOOTH_FACTOR)
                currentHum:Move(SmoothVelocity, false)
            end)
        end

        local function createMoonwalkGui()
            destroyMoonwalkGui()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return end
            MoonwalkGui = Instance.new("ScreenGui")
            MoonwalkGui.Name = "VD_Moonwalk_V3"
            MoonwalkGui.ResetOnSpawn = false
            MoonwalkGui.Parent = pg
            local frame = Instance.new("Frame")
            frame.Name = "MainFrame"
            frame.Parent = MoonwalkGui
            frame.Size = UDim2.fromOffset(180,110)
            frame.Position = CONFIG_MW.GUI_POSITION
            frame.BackgroundColor3 = Color3.fromRGB(10,10,25)
            frame.BackgroundTransparency = 0.15
            frame.Active = true
            frame.Draggable = true
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
            local glow = Instance.new("Frame")
            glow.Name = "Glow"
            glow.Parent = frame
            glow.Size = UDim2.fromScale(1,1)
            glow.BackgroundColor3 = Color3.fromRGB(80,120,255)
            glow.BackgroundTransparency = 0.9
            glow.BorderSizePixel = 0
            Instance.new("UICorner", glow).CornerRadius = UDim.new(0,12)
            local title = Instance.new("TextLabel")
            title.Parent = frame
            title.Size = UDim2.new(1,-50,0,24)
            title.Position = UDim2.fromOffset(0,4)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBold
            title.TextSize = 12
            title.TextColor3 = Color3.fromRGB(150,200,255)
            title.TextXAlignment = Enum.TextXAlignment.Center
            title.Text = "ðŸŒ™ Moonwalk V3"
            local minimizeBtn = Instance.new("TextButton")
            minimizeBtn.Parent = frame
            minimizeBtn.Size = UDim2.fromOffset(20,20)
            minimizeBtn.Position = UDim2.new(1,-46,0,4)
            minimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
            minimizeBtn.Text = "âˆ’"
            minimizeBtn.Font = Enum.Font.GothamBold
            minimizeBtn.TextSize = 14
            minimizeBtn.TextColor3 = Color3.new(1,1,1)
            minimizeBtn.BorderSizePixel = 0
            Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,6)
            local closeBtn = Instance.new("TextButton")
            closeBtn.Parent = frame
            closeBtn.Size = UDim2.fromOffset(20,20)
            closeBtn.Position = UDim2.new(1,-24,0,4)
            closeBtn.BackgroundColor3 = Color3.fromRGB(180,30,30)
            closeBtn.Text = "âœ•"
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 11
            closeBtn.TextColor3 = Color3.new(1,1,1)
            closeBtn.BorderSizePixel = 0
            Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
            local statusLbl = Instance.new("TextLabel")
            statusLbl.Name = "StatusLbl"
            statusLbl.Parent = frame
            statusLbl.Size = UDim2.new(1,0,0,16)
            statusLbl.Position = UDim2.fromOffset(0,30)
            statusLbl.BackgroundTransparency = 1
            statusLbl.Font = Enum.Font.GothamBold
            statusLbl.TextSize = 10
            statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
            statusLbl.TextXAlignment = Enum.TextXAlignment.Center
            statusLbl.Text = "â— OFF"
            local keybindLbl = Instance.new("TextLabel")
            keybindLbl.Parent = frame
            keybindLbl.Size = UDim2.new(1,0,0,14)
            keybindLbl.Position = UDim2.fromOffset(0,46)
            keybindLbl.BackgroundTransparency = 1
            keybindLbl.Font = Enum.Font.Gotham
            keybindLbl.TextSize = 9
            keybindLbl.TextColor3 = Color3.fromRGB(140,140,160)
            keybindLbl.Text = "âŒ¨ï¸ G"
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Name = "ToggleBtn"
            toggleBtn.Parent = frame
            toggleBtn.Size = UDim2.fromOffset(160,28)
            toggleBtn.Position = UDim2.fromOffset(10,70)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,130)
            toggleBtn.Text = "â–¶ START"
            toggleBtn.Font = Enum.Font.GothamBold
            toggleBtn.TextSize = 11
            toggleBtn.TextColor3 = Color3.new(1,1,1)
            toggleBtn.BorderSizePixel = 0
            Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,8)
            local speedBar = Instance.new("Frame")
            speedBar.Name = "SpeedBar"
            speedBar.Parent = frame
            speedBar.Size = UDim2.fromOffset(160,3)
            speedBar.Position = UDim2.fromOffset(10,100)
            speedBar.BackgroundColor3 = Color3.fromRGB(40,40,70)
            speedBar.BorderSizePixel = 0
            Instance.new("UICorner", speedBar).CornerRadius = UDim.new(0,2)
            local speedFill = Instance.new("Frame")
            speedFill.Name = "SpeedFill"
            speedFill.Parent = speedBar
            speedFill.Size = UDim2.fromScale(0,1)
            speedFill.BackgroundColor3 = Color3.fromRGB(0,200,255)
            speedFill.BorderSizePixel = 0
            Instance.new("UICorner", speedFill).CornerRadius = UDim.new(0,2)
            local function updateUI()
                if MoonwalkEnabled then
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(50,200,100)
                    toggleBtn.Text = "â–  STOP"
                    statusLbl.Text = "â— ON"
                    statusLbl.TextColor3 = Color3.fromRGB(0,255,150)
                    glow.BackgroundColor3 = Color3.fromRGB(0,255,150)
                    glow.BackgroundTransparency = 0.85
                    TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(1,1)}):Play()
                else
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,130)
                    toggleBtn.Text = "â–¶ START"
                    statusLbl.Text = "â— OFF"
                    statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
                    glow.BackgroundColor3 = Color3.fromRGB(80,120,255)
                    glow.BackgroundTransparency = 0.9
                    TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(0,1)}):Play()
                end
            end
            local function toggleMoonwalk()
                MoonwalkEnabled = not MoonwalkEnabled
                if MoonwalkEnabled then startMoonwalkInternal() else stopMoonwalkInternal() end
                updateUI()
            end
            local minimized = false
            minimizeBtn.MouseButton1Click:Connect(function()
                minimized = not minimized
                if minimized then
                    frame.Size = UDim2.fromOffset(180,32)
                    statusLbl.Visible = false
                    keybindLbl.Visible = false
                    toggleBtn.Visible = false
                    speedBar.Visible = false
                    minimizeBtn.Text = "+"
                else
                    frame.Size = UDim2.fromOffset(180,110)
                    statusLbl.Visible = true
                    keybindLbl.Visible = true
                    toggleBtn.Visible = true
                    speedBar.Visible = true
                    minimizeBtn.Text = "âˆ’"
                end
            end)
            toggleBtn.MouseButton1Click:Connect(toggleMoonwalk)
            closeBtn.MouseButton1Click:Connect(function()
                if getgenv().VD_Moonwalk_Cleanup then pcall(getgenv().VD_Moonwalk_Cleanup) end
            end)
            updateUI()
            if CONFIG_MW.AUTO_START then task.wait(0.5); toggleMoonwalk() end
        end

        KeybindConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == CONFIG_MW.KEYBIND then
                if MoonwalkGui then
                    MoonwalkEnabled = not MoonwalkEnabled
                    if MoonwalkEnabled then startMoonwalkInternal() else stopMoonwalkInternal() end
                    pcall(function()
                        local frame = MoonwalkGui:FindFirstChild("MainFrame")
                        if not frame then return end
                        local toggleBtn = frame:FindFirstChild("ToggleBtn")
                        local statusLbl = frame:FindFirstChild("StatusLbl")
                        local glow = frame:FindFirstChild("Glow")
                        local speedFill = frame:FindFirstChild("SpeedBar") and frame.SpeedBar:FindFirstChild("SpeedFill")
                        if MoonwalkEnabled then
                            toggleBtn.BackgroundColor3 = Color3.fromRGB(50,200,100)
                            toggleBtn.Text = "â–  STOP"
                            statusLbl.Text = "â— ON"
                            statusLbl.TextColor3 = Color3.fromRGB(0,255,150)
                            glow.BackgroundColor3 = Color3.fromRGB(0,255,150)
                            glow.BackgroundTransparency = 0.85
                            if speedFill then TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(1,1)}):Play() end
                        else
                            toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,130)
                            toggleBtn.Text = "â–¶ START"
                            statusLbl.Text = "â— OFF"
                            statusLbl.TextColor3 = Color3.fromRGB(255,80,80)
                            glow.BackgroundColor3 = Color3.fromRGB(80,120,255)
                            glow.BackgroundTransparency = 0.9
                            if speedFill then TweenService:Create(speedFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(0,1)}):Play() end
                        end
                    end)
                end
            end
        end)

        CharAddedConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.3)
            if MoonwalkEnabled then startMoonwalkInternal() end
        end)

        getgenv().VD_Moonwalk_Cleanup = function()
            MoonwalkEnabled = false
            stopMoonwalkInternal()
            destroyMoonwalkGui()
            if KeybindConn then KeybindConn:Disconnect(); KeybindConn = nil end
            if CharAddedConn then CharAddedConn:Disconnect(); CharAddedConn = nil end
            getgenv().VD_Moonwalk_Cleanup = nil
            print("ðŸŒ™ Moonwalk V3 - Cleanup complete")
        end
        createMoonwalkGui()
        print("ðŸŒ™ Moonwalk V3 - Loaded!")
        print("âŒ¨ï¸ Press G to toggle")

        -- ========================================================================
        -- BUILD UI OXIDELIB
        -- ========================================================================
        local Window = Oxidelib:CreateWindow({
            Name = "Wisnu Hub",
            BrandSubtitle = "Violence District v0.0.1 | by Wisnu Hub",
            Logo = "rbxassetid://130008176530837",
            Size = UDim2.fromOffset(700, 520),
            GuiName = "WisnuHub",
            LoadingAnimation = false,
            ToggleKey = Enum.KeyCode.RightShift,
            Mobile = true,
            Scale = 0.92,
        })

        -- BUAT TABS
        local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
        local ESPTab = Window:AddTab({ Name = "ESP", Icon = "eye" })
        local MiscTab = Window:AddTab({ Name = "Misc", Icon = "sliders" })
        local VisualTab = Window:AddTab({ Name = "Visual", Icon = "sparkles" })
        local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

        -- ===== PLAYER TAB - SURVIVOR =====
        local SurvivorSub = PlayerTab:AddSubTab("Survivor")
        
        SurvivorSub:AddToggle({ Name = "Auto Skill Check", Default = false, Callback = function(v) 
            Auto.SkillCheck = v
            GenEnabled = v
            if v then 
                GenMode = Auto.SkillCheckMode
                StartGenerator() 
            else 
                StopGenerator() 
            end 
        end })
        SurvivorSub:AddDropdown({ Name = "Skill Check Mode", Options = {"Instant", "Legit", "Random"}, Default = "Instant", Callback = function(v) 
            Auto.SkillCheckMode = v 
            GenMode = v 
            if GenEnabled then 
                StartGenerator() 
            end 
        end })
        SurvivorSub:AddToggle({ Name = "Boost Gen Bypass", Default = false, Callback = function(v) setGenBypass(v) end })
        SurvivorSub:AddToggle({ Name = "Auto Drop Pallet", Default = false, Callback = function(v) Auto.PalletDrop = v end })
        SurvivorSub:AddSlider({ Name = "Pallet Distance", Min = 5, Max = 50, Default = 6, Callback = function(v) Auto.PalletDropDist = v end })
        SurvivorSub:AddToggle({ Name = "Auto Flee Killer", Default = false, Callback = function(v) AutoFlee.Enabled = v end })
        SurvivorSub:AddToggle({ Name = "Anti Fall Damage", Default = false, Callback = function(v) PlayerMods.AntiFall = v end })
        SurvivorSub:AddToggle({ Name = "Anti KnockDown", Default = false, Callback = function(v) PlayerMods.GodMode = v end })
        SurvivorSub:AddToggle({ Name = "Fast Vault", Default = false, Callback = function(v) FastVault.Enabled = v end })
        SurvivorSub:AddSlider({ Name = "Vault Speed", Min = 1, Max = 5, Default = 1.2, Callback = function(v) FastVault.Speed = v end })
        SurvivorSub:AddToggle({ Name = "Disable Local Vault", Default = false, Callback = function(v) PlayerMods.AntiVault = v end })
        SurvivorSub:AddButton({ Name = "Instan Escape", Callback = function() teleportToFinishLine() end })

        -- ===== PLAYER TAB - KILLER =====
        local KillerSub = PlayerTab:AddSubTab("Killer")
        
        KillerSub:AddToggle({ Name = "Block All Vaults", Default = false, Callback = function(v) Killer.BlockVaults = v end })
        KillerSub:AddToggle({ Name = "Anti Blind", Default = false, Callback = function(v) Killer.AntiBlind = v end })
        KillerSub:AddToggle({ Name = "Auto Stalk (Myers)", Default = false, Callback = function(v) AutoStalk.Enabled = v; if v then startAutoStalk() else stopAutoStalk() end end })
        KillerSub:AddToggle({ Name = "Bypass Cooldown (Abyss)", Default = false, Callback = function(v) Killer.BypassCooldown = v; if v then StartCooldownBypass() else StopCooldownBypass() end end })
        KillerSub:AddToggle({ Name = "Bypass Cooldown (Hidden)", Default = false, Callback = function(v) Killer.BypassLeap = v; if v then StartLeapBypass() end end })
        KillerSub:AddToggle({ Name = "Auto Kill All", Default = false, Callback = function(v) Killer.KillAll = v end })
        KillerSub:AddToggle({ Name = "AimLock Attack", Default = false, Callback = function(v) AttackAim.Enabled = v; if v then startAttackAim() end end })
        KillerSub:AddDropdown({ Name = "Aimlock Mode", Options = {"Normal", "Spear"}, Default = "Normal", Callback = function(v) State.AttackAimMode = v end })
        KillerSub:AddSlider({ Name = "Spear Gravity", Min = 10, Max = 200, Default = 50, Callback = function(v) SpearAim.Gravity = v end })
        KillerSub:AddSlider({ Name = "Spear Speed", Min = 20, Max = 300, Default = 100, Callback = function(v) SpearAim.Speed = v end })
        KillerSub:AddDivider()
        KillerSub:AddDropdown({ Name = "Masked Power", Options = MaskedPowers, Default = "Cobra", Callback = function(v) Masked.CurrentPower = v end })
        KillerSub:AddButton({ Name = "Activate Power", Callback = function() local Event = GetRemote("Remotes.Killers.Masked.Activatepower"); if Event then Event:FireServer(Masked.CurrentPower) end end })
        KillerSub:AddButton({ Name = "Deactivate Power", Callback = function() local Event = GetRemote("Remotes.Killers.Masked.Deactivatepower"); if Event then Event:FireServer() end end })

        -- ===== PLAYER TAB - PARRY =====
        local ParrySub = PlayerTab:AddSubTab("Parry")
        
        ParrySub:AddToggle({ Name = "Auto Parry", Default = false, Callback = function(v) Config.Surv_AutoParry = v end })
        ParrySub:AddToggle({ Name = "Safety Parry", Default = false, Callback = function(v) Config.Surv_ParrySafety = v end })
        ParrySub:AddToggle({ Name = "Aggressive Mode", Default = false, Callback = function(v) Config.Surv_ParryAggressive = v end })
        ParrySub:AddToggle({ Name = "ESP Range Circle", Default = true, Callback = function(v) Config.Surv_ParryCircle = v end })
        ParrySub:AddSlider({ Name = "Parry Radius", Min = 5, Max = 25, Default = 15, Callback = function(v) Config.Surv_ParryRadius = v end })
        ParrySub:AddSlider({ Name = "Face Sensitivity", Min = -10, Max = 10, Default = 7, Callback = function(v) Config.Surv_ParryFace = v / 10 end })
        ParrySub:AddMultiDropdown({ Name = "Ignore Skills", Options = {"Hidden S1", "Abyssal S1"}, Default = {}, Callback = function(v) local t = {}; for _, s in ipairs(v) do t[s] = true end; Config.Ignored_Skills_List = t end })
        ParrySub:AddToggle({ Name = "Auto Crouch (Dodge S1)", Default = false, Callback = function(v) Config.Surv_AutoCrouch = v end })
        ParrySub:AddDivider()
        ParrySub:AddToggle({ Name = "Fake Parry", Default = false, Callback = function(v) FakeParry.Enabled = v; if IsMobile() then if v then CreateFakeParryButton() else RemoveFakeParryButton() end end end })
        ParrySub:AddDropdown({ Name = "Fake Parry Animation", Options = {"Enten", "Stopwatch", "Fih", "BloodShield"}, Default = "Enten", Callback = function(v) FakeParry.Animation = v end })

        -- ===== PLAYER TAB - TWIST OF FATE (SILENT AIM) =====
        local ToFSub = PlayerTab:AddSubTab("Twist of Fate")
        
        ToFSub:AddToggle({ Name = "Silent Aim (Pistol)", Default = false, Callback = function(v) 
            AimConfig.Aim_Silent = v 
            if v then Oxidelib:Notify({ Title = "Silent Aim", Content = "ON - Target: " .. AimConfig.Pistol_Target, Duration = 2 }) else Oxidelib:Notify({ Title = "Silent Aim", Content = "OFF", Duration = 2 }) end
        end })
        ToFSub:AddToggle({ Name = "Block Aim Knocked", Default = false, Callback = function(v) AimConfig.Pistol_BlockKnocked = v end })
        ToFSub:AddToggle({ Name = "Silent Aim (Flashlight)", Default = false, Callback = function(v) AimConfig.Flash_Silent = v end })
        ToFSub:AddSlider({ Name = "Flash Head Offset (Y)", Min = 1, Max = 15, Default = 8, Step = 0.5, Callback = function(v) AimConfig.Flash_YOffset = v end })
        ToFSub:AddToggle({ Name = "Lock Aim", Default = false, Callback = function(v) AimConfig.LockAim = v end })
        ToFSub:AddDivider()
        ToFSub:AddDropdown({ Name = "Target", Options = {"Killer", "Survivor", "SCP"}, Default = "Killer", Callback = function(v) AimConfig.Pistol_Target = v end })
        ToFSub:AddToggle({ Name = "Pistol FOV Mode", Default = false, Callback = function(v) AimConfig.Pistol_FOVMode = v end })
        ToFSub:AddToggle({ Name = "Show Pistol FOV", Default = false, Callback = function(v) AimConfig.Pistol_ShowFOV = v end })
        ToFSub:AddSlider({ Name = "Pistol FOV Radius", Min = 50, Max = 500, Default = 150, Step = 5, Callback = function(v) AimConfig.Pistol_FOV = v end })
        ToFSub:AddDropdown({ Name = "Target Part", Options = {"Head", "Torso", "Root", "HumanoidRootPart"}, Default = "Torso", Callback = function(v) AimConfig.AIM_TargetPart = v end })
        ToFSub:AddToggle({ Name = "Hide Silent Laser", Default = false, Callback = function(v) 
            AimConfig.HideSilentLaser = v 
            if pistolLaser then pistolLaser.Transparency = v and 1 or 0 end
        end })
        ToFSub:AddDivider()
        ToFSub:AddLabel({ Name = "âš¡ Keybinds: K=Killer, J=Survivor, L=SCP" })

        -- ===== PLAYER TAB - AIMLOCK =====
        local AimSub = PlayerTab:AddSubTab("AimLock")
        
        AimSub:AddToggle({ Name = "Aim Lock", Default = false, Callback = function(v) GunAim.Enabled = v; if v then startGunAim() end end })
        AimSub:AddDropdown({ Name = "Target", Options = {"Killer", "Survivor", "SCP"}, Default = "Killer", Callback = function(v) GunAim.TargetMode = v end })
        AimSub:AddDropdown({ Name = "Aim Part", Options = {"Head", "HumanoidRootPart", "Torso", "Root"}, Default = "HumanoidRootPart", Callback = function(v) GunAim.AimPart = v end })
        AimSub:AddSlider({ Name = "FOV", Min = 50, Max = 1000, Default = 250, Callback = function(v) GunAim.FOV = v end })
        AimSub:AddSlider({ Name = "Prediction", Min = 0, Max = 1, Default = 0.12, Callback = function(v) GunAim.PredictStrength = v end })

        -- ===== PLAYER TAB - CROSSHAIR =====
        local CrosshairSub = PlayerTab:AddSubTab("Crosshair")
        
        CrosshairSub:AddToggle({ Name = "Enable Crosshair", Default = false, Callback = function(v) Crosshair.Enabled = v end })
        CrosshairSub:AddColorPicker({ Name = "Crosshair Color", Default = Color3.fromRGB(255,255,255), Callback = function(c) Crosshair.Color = c end })
        CrosshairSub:AddDropdown({ Name = "Style", Options = {"Plus", "Dot", "Circle"}, Default = "Plus", Callback = function(v) Crosshair.Style = v end })
        CrosshairSub:AddSlider({ Name = "Position X", Min = -100, Max = 100, Default = 0, Callback = function(v) Crosshair.OffsetX = v end })
        CrosshairSub:AddSlider({ Name = "Position Y", Min = -100, Max = 100, Default = 0, Callback = function(v) Crosshair.OffsetY = v end })

        -- ===== ESP TAB =====
        local ChamSub = ESPTab:AddSubTab("ESP Cham")
        
        ChamSub:AddToggle({ Name = "ESP Survivor", Default = false, Callback = function(v) ESP.Survivor = v end })
        ChamSub:AddColorPicker({ Name = "Survivor Color", Default = TeamColors.Survivor, Callback = function(c) TeamColors.Survivor = c end })
        ChamSub:AddToggle({ Name = "ESP Killer", Default = false, Callback = function(v) ESP.Killer = v end })
        ChamSub:AddColorPicker({ Name = "Killer Color", Default = TeamColors.Killer, Callback = function(c) TeamColors.Killer = c end })
        ChamSub:AddToggle({ Name = "Generator", Default = false, Callback = function(v) ESP.Generator = v end })
        ChamSub:AddColorPicker({ Name = "Generator Color", Default = GeneratorColor, Callback = function(c) GeneratorColor = c end })
        ChamSub:AddToggle({ Name = "SCP", Default = false, Callback = function(v) ESP.SCP = v end })
        ChamSub:AddColorPicker({ Name = "SCP Color", Default = SCPColor, Callback = function(c) SCPColor = c end })
        ChamSub:AddToggle({ Name = "Pallet", Default = false, Callback = function(v) ESP.Pallet = v end })
        ChamSub:AddColorPicker({ Name = "Pallet Color", Default = PalletColor, Callback = function(c) PalletColor = c end })
        ChamSub:AddToggle({ Name = "Window", Default = false, Callback = function(v) ESP.Window = v end })
        ChamSub:AddColorPicker({ Name = "Window Color", Default = WindowColor, Callback = function(c) WindowColor = c end })

        -- ===== ESP STATUS =====
        local StatusSub = ESPTab:AddSubTab("ESP Status")
        
        StatusSub:AddToggle({ Name = "Enable Status ESP", Default = false, Callback = function(v) ESPStatus.Enabled = v end })
        StatusSub:AddToggle({ Name = "Show Name", Default = true, Callback = function(v) ESPStatus.ShowName = v end })
        StatusSub:AddToggle({ Name = "Show Item", Default = true, Callback = function(v) ESPStatus.ShowItem = v end })
        StatusSub:AddToggle({ Name = "Show Distance", Default = true, Callback = function(v) ESPStatus.ShowDistance = v end })
        StatusSub:AddToggle({ Name = "Show Health", Default = false, Callback = function(v) ESPStatus.ShowHealth = v end })
        StatusSub:AddSlider({ Name = "Status Radius", Min = 20, Max = 500, Default = 100, Callback = function(v) ESPStatus.Radius = v end })
        StatusSub:AddDivider()
        StatusSub:AddButton({ Name = "TP Generator (Loop)", Callback = TeleportToGenerator })
        StatusSub:AddButton({ Name = "TP Hook (Loop)", Callback = TeleportToHook })
        StatusSub:AddButton({ Name = "TP Gate (Loop)", Callback = TeleportToGate })
        StatusSub:AddButton({ Name = "TP Pallet (Loop)", Callback = TeleportToPallet })
        StatusSub:AddButton({ Name = "TP Window (Loop)", Callback = TeleportToWindow })
        StatusSub:AddDivider()
        StatusSub:AddButton({ Name = "Refresh Map Cache", Callback = RefreshMapForTeleport })

        -- ===== MISC TAB =====
        local MoveSub = MiscTab:AddSubTab("Movement")
        
        MoveSub:AddToggle({ Name = "Walk Speed", Default = false, Callback = function(v) Movement.WalkSpeedEnabled = v; if v then applyWalkSpeed() else local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed = 16 end end end })
        MoveSub:AddSlider({ Name = "Walk Speed Value", Min = 16, Max = 32, Default = 17.6, Callback = function(v) Movement.WalkSpeedValue = v; if Movement.WalkSpeedEnabled then applyWalkSpeed() end end })
        MoveSub:AddToggle({ Name = "No Clip", Default = false, Callback = function(v) toggleNoClip(v) end })
        MoveSub:AddToggle({ Name = "Custom Jump Power", Default = false, Callback = function(v) Movement.JumpPowerEnabled = v; if v then applyJumpPower() else local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); if hum then hum.JumpPower = 50 end end end })
        MoveSub:AddSlider({ Name = "Jump Power Value", Min = 0, Max = 300, Default = 50, Callback = function(v) Movement.JumpPowerValue = v; if Movement.JumpPowerEnabled then applyJumpPower() end end })

        -- ===== EMOTE =====
        local EmoteSub = MiscTab:AddSubTab("Emote")
        
        EmoteSub:AddDropdown({ Name = "Select Emote", Options = EmoteList, Default = "Mannrobics", Callback = function(v) Emote.Selected = v; if EmoteButton.GuiInstance then local label = EmoteButton.GuiInstance:FindFirstChild("TextLabel"); if label then label.Text = v end end end })
        EmoteSub:AddButton({ Name = "Play Emote", Callback = function() playEmote(Emote.Selected) end })
        EmoteSub:AddToggle({ Name = "Show Emote Button", Default = false, Callback = function(v) EmoteButton.Show = v; if v then createEmoteButton() else removeEmoteButton() end end })

        -- ===== FAKE CHAT =====
        local FakeSub = MiscTab:AddSubTab("Fake Chat")
        
        FakeSub:AddToggle({ Name = "Enable Fake Tag", Default = false, Callback = function(v) FakeTag.Enabled = v end })
        FakeSub:AddInput({ Name = "Chat Tag", Default = "[WISNU]", Callback = function(v) if v ~= "" then FakeTag.Text = v end end })

        -- ===== VISUAL TAB =====
        local GraphicSub = VisualTab:AddSubTab("Graphics")
        
        GraphicSub:AddToggle({ Name = "Fullbright", Default = false, Callback = function(v) Visual.Fullbright = v; applyVisual() end })
        GraphicSub:AddToggle({ Name = "No Shadow", Default = false, Callback = function(v) Visual.NoShadow = v end })
        GraphicSub:AddToggle({ Name = "Low Graphics", Default = false, Callback = function(v) Visual.LowGraphics = v; applyOptimization() end })
        GraphicSub:AddToggle({ Name = "No Screen Effects", Default = false, Callback = function(v) Visual.NoScreenEffects = v; applyNoScreenEffects() end })
        GraphicSub:AddToggle({ Name = "Clean Sky", Default = false, Callback = function(v) Visual.CleanSky = v; applyOptimization() end })
        GraphicSub:AddButton({ Name = "Potato Mode", Callback = function() Lighting.GlobalShadows = false; Lighting.ShadowSoftness = 0; Lighting.FogEnd = 9e9; for _, effect in ipairs(Lighting:GetDescendants()) do if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Clouds") then pcall(function() effect.Enabled = false end) end; if effect:IsA("Sky") then pcall(function() effect:Destroy() end) end end; local terrain = workspace.Terrain; if terrain then pcall(function() terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0; terrain.WaterReflectance = 0; terrain.WaterTransparency = 0; terrain.Decoration = false end) end; Oxidelib:Notify({ Title = "Potato Mode", Content = "Optimasi ekstrem selesai! FPS meningkat.", Duration = 3 }) end })

        -- ===== MORPH =====
        local MorphSub = VisualTab:AddSubTab("Morph")
        MorphSub:AddButton({ Name = "Apply Korless", Callback = ApplyKorless })

        -- ===== CLOCK =====
        local ClockSub = VisualTab:AddSubTab("Clock")
        
        ClockSub:AddSlider({ Name = "Clock Time", Min = 0, Max = 24, Default = 14, Callback = function(v) Visual.ClockTime = v; Visual.Ambient = true; applyVisual() end })
        ClockSub:AddSlider({ Name = "Brightness", Min = 0, Max = 5, Default = 2, Callback = function(v) Visual.Brightness = v; Visual.Ambient = true; applyVisual() end })

        -- ===== ZOOM =====
        local ZoomSub = VisualTab:AddSubTab("Zoom")
        
        ZoomSub:AddToggle({ Name = "Third Person View", Default = false, Callback = function(v) Killer.ThirdPerson = v; if not v then UpdateThirdPerson() end end })
        ZoomSub:AddToggle({ Name = "Unlimited Zoom Out", Default = false, Callback = function(v) CameraZoom.UnlimitedZoom = v; applyUnlimitedZoom() end })
        ZoomSub:AddSlider({ Name = "Max Zoom Distance", Min = 100, Max = 5000, Default = 1000, Callback = function(v) CameraZoom.MaxDistance = v; if CameraZoom.UnlimitedZoom then applyUnlimitedZoom() end end })
        ZoomSub:AddToggle({ Name = "Custom FOV", Default = false, Callback = function(v) CameraZoom.FOVEnabled = v; applyCameraFOV() end })
        ZoomSub:AddSlider({ Name = "Camera FOV", Min = 40, Max = 120, Default = 70, Callback = function(v) CameraZoom.FOV = v; if CameraZoom.FOVEnabled then applyCameraFOV() end end })

        -- ===== SETTINGS TAB =====
        local SettingsSub = SettingsTab:AddSubTab("Menu")
        
        SettingsSub:AddToggle({ Name = "Custom Cursor", Default = true, Callback = function(v) Oxidelib.ShowCustomCursor = v end })
        SettingsSub:AddDropdown({ Name = "Notification Side", Options = {"Left", "Right"}, Default = "Right", Callback = function(v) Oxidelib:SetNotifySide(v) end })
        SettingsSub:AddDropdown({ Name = "DPI Scale", Options = {"50%", "75%", "85%", "100%", "125%", "150%"}, Default = "85%", Callback = function(v) local scale = tonumber(v:gsub("%%","")) / 100; Oxidelib:SetDPIScale(scale) end })
        SettingsSub:AddToggle({ Name = "Glow AccentBar", Default = true, Callback = function(v) Window:SetHeaderGlow(v) end })
        SettingsSub:AddToggle({ Name = "Show Profile", Default = true, Callback = function(v) Window:SetProfileVisible(v) end })
        SettingsSub:AddDivider()
        SettingsSub:AddButton({ Name = "Unload Script", Callback = function() Window:Destroy() end })
        SettingsSub:AddSlider({ Name = "UI Scale", Min = 50, Max = 150, Default = 92, Callback = function(v) local containerScale = Window.containerScale; if containerScale then containerScale.Scale = v / 100 end end })
        SettingsSub:AddDropdown({ Name = "Theme", Options = {"Dark", "Light", "OLED"}, Default = "Dark", Callback = function(v) Oxidelib:SetTheme(v) end })
        SettingsSub:AddDivider()
        SettingsSub:AddButton({ Name = "Save Config", Callback = function() Oxidelib:SaveConfig("autoload") end })
        SettingsSub:AddButton({ Name = "Load Config", Callback = function() Oxidelib:LoadConfig("autoload") end })

        -- ========================================================================
        -- CHARACTER EVENTS & MAIN LOOPS
        -- ========================================================================
        LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.8)
            applyJumpPower()
            applyWalkSpeed()
            if Movement.NoClip then task.wait(0.3); toggleNoClip(true) end
            applyUnlimitedZoom()
            hookVault(char)
            TeleportIndex.Generator = 1; TeleportIndex.Hook = 1; TeleportIndex.Gate = 1; TeleportIndex.Pallet = 1; TeleportIndex.Window = 1
        end)

        RunService.Heartbeat:Connect(function()
            local now = tick()
            HandleAutoPallet()
            if now - Timers.lastVaultBlock >= 1.5 then Timers.lastVaultBlock = now; HandleBlockVaults() end
            if now - Timers.lastGodMode >= 0.1 then Timers.lastGodMode = now; applyGodMode() end
            if now - Timers.lastKillerUpdate >= 0.05 then
                Timers.lastKillerUpdate = now
                if Killer.KillAll then
                    local root = getRoot()
                    if root then
                        if not State.KillerTarget or not State.KillerTarget:FindFirstChild("Humanoid") or State.KillerTarget.Humanoid.Health <= 35 then
                            State.KillerTarget = GetNearestAliveSurvivor()
                        end
                        if State.KillerTarget then
                            local targetHRP = State.KillerTarget:FindFirstChild("HumanoidRootPart")
                            if targetHRP then
                                local velocity = targetHRP.AssemblyLinearVelocity
                                local predict = velocity * 0.15
                                local targetPos = targetHRP.Position + predict
                                local behind = targetHRP.CFrame.LookVector * -3
                                root.CFrame = CFrame.new(targetPos + behind, targetPos)
                            end
                            pcall(function() AttackEvent:FireServer(false) end)
                        end
                    end
                end
                if Movement.WalkSpeedEnabled then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        if shouldDisableWalkSpeed() then
                            if hum.WalkSpeed == Movement.WalkSpeedValue then hum.WalkSpeed = Movement.OriginalWalkSpeed end
                        else
                            if hum.WalkSpeed ~= Movement.WalkSpeedValue then hum.WalkSpeed = Movement.WalkSpeedValue end
                        end
                    end
                end
            end
        end)

        RunService.RenderStepped:Connect(function()
            local root = getRoot()
            if not root then return end
            local now = tick()
            
            if now - Timers.lastESPUpdate >= 0.05 then
                Timers.lastESPUpdate = now
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local char = p.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local hrp2 = char:FindFirstChild("HumanoidRootPart")
                            if hrp2 then
                                local distance = (hrp2.Position - root.Position).Magnitude
                                if distance <= ESP.Distance then
                                    if ESP.Survivor and p.Team and p.Team.Name == "Survivors" then createESP(char, TeamColors.Survivor)
                                    elseif ESP.Killer and IsKiller(p) then createESP(char, TeamColors.Killer)
                                    else removeESP(char) end
                                else removeESP(char) end
                            end
                            createStatusESP(p, char, root)
                        else removeESP(char) end
                    end
                end
                if ESP.Generator then
                    for gen in pairs(ESPCache.Generators) do UpdateGenerator(gen) end
                end
                for obj in pairs(ESPCache.Windows) do UpdateMapESP(obj, root) end
                for obj in pairs(ESPCache.Pallets) do UpdateMapESP(obj, root) end
                UpdateSCPEsp(root)
                applyVisual()
                applyNoScreenEffects()
                updateParryCircle()
            end
            
            drawCrosshair()
            UpdateThirdPerson()
            
            if Config.Surv_ParryCircle and Config.Surv_AutoParry and root then
                if not State.AutoParryAdornment or State.AutoParryAdornment.Parent ~= root then
                    if State.AutoParryAdornment then State.AutoParryAdornment:Destroy() end
                    State.AutoParryAdornment = Instance.new("CylinderHandleAdornment")
                    State.AutoParryAdornment.Name = "AutoParryCircleESP"
                    State.AutoParryAdornment.Height = 0.05
                    State.AutoParryAdornment.Transparency = 0.3
                    State.AutoParryAdornment.Adornee = root
                    State.AutoParryAdornment.Parent = root
                    State.AutoParryAdornment.ZIndex = 0
                    State.AutoParryAdornment.AlwaysOnTop = false
                end
                local cR = Config.Surv_ParryRadius
                State.AutoParryAdornment.Radius = cR
                State.AutoParryAdornment.InnerRadius = math.max(0.1, cR - 0.15)
                State.AutoParryAdornment.CFrame = CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
                if State.ParryCooldown then State.AutoParryAdornment.Color3 = Color3.fromRGB(255,128,0)
                elseif Config.Surv_ParryAggressive then State.AutoParryAdornment.Color3 = Color3.fromRGB(255,0,0)
                else State.AutoParryAdornment.Color3 = Color3.fromRGB(0,255,255) end
            elseif State.AutoParryAdornment then
                State.AutoParryAdornment:Destroy(); State.AutoParryAdornment = nil
            end

            -- ====================================================================
            -- SILENT AIM LOOP (OXIO)
            -- ====================================================================
            if isAimingFlash and AimConfig.Flash_Silent then
                local targetPart = getKillerTargetForFlash()
                if targetPart then
                    local myChar = LocalPlayer.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local targetPos = targetPart.Position + Vector3.new(0, AimConfig.Flash_YOffset, 0)
                    local cam = workspace.CurrentCamera
                    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, targetPos), 0.5)
                    if myHRP then
                        local goalHrp = CFrame.lookAt(myHRP.Position, Vector3.new(targetPos.X, myHRP.Position.Y, targetPos.Z))
                        myHRP.CFrame = myHRP.CFrame:Lerp(goalHrp, 0.5)
                    end
                end
            end
            
            if isChargingPistol then
                if lockedPistolTarget and AimConfig.LockAim and lockedPistolTarget.Parent and lockedPistolTarget.Parent:FindFirstChild("Humanoid") and lockedPistolTarget.Parent.Humanoid.Health > 0 then
                    local cam = workspace.CurrentCamera
                    local targetCFrame = CFrame.lookAt(cam.CFrame.Position, lockedPistolTarget.Position)
                    cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.15)
                else
                    lockedPistolTarget = getPistolTarget()
                end
            end
            
            if isChargingPistol and AimConfig.Aim_Silent then
                local targetPart = getPistolTarget()
                if targetPart then
                    CreatePistolLaser()
                    local myChar = LocalPlayer.Character
                    local leftArm = myChar and (myChar:FindFirstChild("Left Arm") or myChar:FindFirstChild("LeftHand"))
                    local startPos = leftArm and leftArm.Position or (myChar and myChar:GetPivot().Position or Vector3.new())
                    local targetPos = targetPart.Position
                    local targetVel = targetPart.AssemblyLinearVelocity
                    targetVel = Vector3.new(targetVel.X, 0, targetVel.Z)
                    local distance = (targetPos - startPos).Magnitude
                    local bulletSpeed = 400
                    local timeToHit = distance / bulletSpeed
                    local predictedPos = targetPos + (targetVel * timeToHit)
                    local offset = Vector3.new(0, -1.2, 0)
                    local endPos = predictedPos + offset
                    if pistolLaser then
                        pistolLaser.Parent = workspace
                        pistolLaser.Transparency = AimConfig.HideSilentLaser and 1 or 0
                        local newDist = (endPos - startPos).Magnitude
                        if newDist > 0 then
                            pistolLaser.Size = Vector3.new(0.05, 0.05, newDist)
                            pistolLaser.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -newDist / 2)
                        end
                    end
                else
                    if pistolLaser and pistolLaser.Parent then
                        pistolLaser.Parent = nil
                    end
                end
            else
                if pistolLaser and pistolLaser.Parent then
                    pistolLaser.Parent = nil
                end
            end
            
            if AimConfig.Aim_Silent and AimConfig.Pistol_ShowFOV and AimConfig.Pistol_FOVMode then
                PistolFOVCircle.Visible = true
                PistolFOVCircle.Radius = AimConfig.Pistol_FOV
                PistolFOVCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                local target = getPistolTarget()
                PistolFOVCircle.Color = target and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 100)
            else
                PistolFOVCircle.Visible = false
            end
        end)

        RunService.RenderStepped:Connect(function()
            if CameraZoom.FOVEnabled then
                local cam = workspace.CurrentCamera
                if cam and cam.FieldOfView ~= CameraZoom.FOV then cam.FieldOfView = CameraZoom.FOV end
            end
        end)

        if LocalPlayer.Character then
            hookVault(LocalPlayer.Character)
            startGunAim()
        end

        -- Parry Sensor Setup
        for _, p in pairs(Players:GetPlayers()) do SetupPlayer(p) end
        Players.PlayerAdded:Connect(SetupPlayer)

        task.spawn(function()
            while true do
                task.wait(0.8)
                if Config.Surv_AutoParry then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and IsKiller(p) and p.Character then
                            TryAttach(p)
                        end
                    end
                end
            end
        end)

        -- ========================================================================
        -- NOTIFIKASI
        -- ========================================================================
        Oxidelib:Notify({ Title = "Wisnu Hub", Content = "Berhasil Dimuat! (Semua Fitur)", Duration = 3 })
        pcall(function() Oxidelib:LoadConfig("autoload") end)

        print("âœ… Wisnu Hub - Semua fitur aktif!")
    end)
end

-- ==============================================
-- JALANKAN SISTEM KEY
-- ==============================================
Onyx.Callbacks.OnSuccess = function()
    MainScript()
end

Onyx:LaunchJunkie({
    Service = "Wisnu",
    Identifier = "1163413",
    Provider = "WISNU HUB"
})
