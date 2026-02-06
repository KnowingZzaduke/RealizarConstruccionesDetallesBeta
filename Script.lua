local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService") -- Añadido del Script 2
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- 🔗 CONEXIÓN
-- ==========================================
local Connections = ReplicatedStorage:WaitForChild("Connections")
local Remotes = Connections:WaitForChild("Remotes")
local PlotSystem = Remotes:WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox"
local RADIO_HORIZONTAL = 45
local ALTURA_MAXIMA = 900
local TRANSPARENCIA_MOLDE = 0.5
local VELOCIDAD_VUELO = 400 -- Configuración del Script 2

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {}
local fantasmasCreados = {}
local bloqueSeleccionado = nil
local menuAbierto = true
local procesoActivo = false

local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Gestor V42 (Flight Mode)"
tool.Parent = LocalPlayer.Backpack

local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 100)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (DISEÑO V19 RESTAURADO)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local toggleBtn = Instance.new("TextButton"); toggleBtn.Name = "ToggleMenu"; toggleBtn.Size = UDim2.new(0, 45, 0, 45); toggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0); toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200); toggleBtn.Text = "📐"; toggleBtn.TextSize = 25; toggleBtn.TextColor3 = Color3.new(1,1,1); toggleBtn.Parent = screenGui; Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

local mainFrame = Instance.new("Frame"); mainFrame.Name = "MainFrame"; mainFrame.Size = UDim2.new(0, 230, 0, 420); mainFrame.Position = UDim2.new(0.15, 0, 0.25, 0); mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); mainFrame.Parent = screenGui; Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local topBar = Instance.new("Frame"); topBar.Size = UDim2.new(1, 0, 0, 35); topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35); topBar.Parent = mainFrame; Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)
local title = Instance.new("TextLabel"); title.Text = "🏗️ V42 FLIGHT"; title.Size = UDim2.new(0.8, 0, 1, 0); title.Position = UDim2.new(0.05, 0, 0, 0); title.BackgroundTransparency = 1; title.TextColor3 = Color3.fromRGB(0, 255, 100); title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = topBar
local closeMini = Instance.new("TextButton"); closeMini.Text = "-"; closeMini.Size = UDim2.new(0.15, 0, 1, 0); closeMini.Position = UDim2.new(0.85, 0, 0, 0); closeMini.BackgroundTransparency = 1; closeMini.TextColor3 = Color3.fromRGB(200, 200, 200); closeMini.TextSize = 20; closeMini.Font = Enum.Font.GothamBold; closeMini.Parent = topBar

local nameInput = Instance.new("TextBox"); nameInput.PlaceholderText = "Nombre archivo..."; nameInput.Size = UDim2.new(0.65, 0, 0, 30); nameInput.Position = UDim2.new(0.05, 0, 0.12, 0); nameInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45); nameInput.TextColor3 = Color3.new(1,1,1); nameInput.Parent = mainFrame; Instance.new("UICorner", nameInput)
local btnSave = Instance.new("TextButton"); btnSave.Text = "💾"; btnSave.Size = UDim2.new(0.2, 0, 0, 30); btnSave.Position = UDim2.new(0.75, 0, 0.12, 0); btnSave.BackgroundColor3 = Color3.fromRGB(0, 120, 200); btnSave.TextColor3 = Color3.new(1,1,1); btnSave.Parent = mainFrame; Instance.new("UICorner", btnSave)

local scrollList = Instance.new("ScrollingFrame"); scrollList.Size = UDim2.new(0.9, 0, 0.25, 0); scrollList.Position = UDim2.new(0.05, 0, 0.22, 0); scrollList.BackgroundColor3 = Color3.fromRGB(35, 35, 35); scrollList.BorderSizePixel = 0; scrollList.Parent = mainFrame
local layoutFiles = Instance.new("UIListLayout"); layoutFiles.Padding = UDim.new(0, 4); layoutFiles.Parent = scrollList

local actionsFrame = Instance.new("Frame"); actionsFrame.Name = "ActionsFrame"; actionsFrame.Size = UDim2.new(0.9, 0, 0.48, 0); actionsFrame.Position = UDim2.new(0.05, 0, 0.50, 0); actionsFrame.BackgroundTransparency = 1; actionsFrame.Parent = mainFrame
local layoutActions = Instance.new("UIListLayout"); layoutActions.Padding = UDim.new(0, 6); layoutActions.SortOrder = Enum.SortOrder.LayoutOrder; layoutActions.Parent = actionsFrame
local statusLabel = Instance.new("TextLabel"); statusLabel.Size = UDim2.new(1,0,0,15); statusLabel.Position = UDim2.new(0,0,0.96,0); statusLabel.BackgroundTransparency = 1; statusLabel.TextColor3 = Color3.new(0.5,0.5,0.5); statusLabel.TextSize = 10; statusLabel.Parent = mainFrame

local function hacerArrastrable(frameDrag, frameMover)
    local dragging, dragInput, dragStart, startPos
    frameDrag.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = frameMover.Position end end)
    frameDrag.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; frameMover.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end
hacerArrastrable(topBar, mainFrame)
local function toggleGUI() menuAbierto = not menuAbierto; if menuAbierto then mainFrame:TweenPosition(UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 0.25, 0), "Out", "Quad", 0.3, true) else mainFrame:TweenPosition(UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1.5, 0), "In", "Quad", 0.3, true) end end
toggleBtn.MouseButton1Click:Connect(toggleGUI); closeMini.MouseButton1Click:Connect(toggleGUI)

-- ==========================================
-- 🧠 FUNCIONES BASE
-- ==========================================
function notificar(texto) statusLabel.Text = texto; game:GetService("StarterGui"):SetCore("SendNotification", {Title="Builder V42", Text=texto, Duration=1.5}) end
function redondearCFrame(cf) local x, y, z = cf.X, cf.Y, cf.Z; return CFrame.new(x, y, z) * (cf - cf.Position) end

function obtenerNombreReal(p)
    if p.Parent and p.Parent:IsA("Model") and p.Parent.Name ~= "Model" then return p.Parent.Name end
    return "part_cube"
end

function encontrarBloqueYSuID(posicionCFrame)
    local partesCercanas = workspace:GetPartBoundsInRadius(posicionCFrame.Position, 0.8)
    for _, parte in pairs(partesCercanas) do
        if parte:IsA("BasePart") and parte.Name ~= "Baseplate" and not parte.Name:find("Ghost") and parte.Transparency < 1 then
            local modeloPadre = parte.Parent
            if modeloPadre then
                local id = modeloPadre:GetAttribute("Id") or modeloPadre:GetAttribute("ID")
                if id then return parte, id end
            end
        end
    end
    return nil, nil
end

function obtenerRotacionJugador()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local x, y, z = hrp.CFrame:ToEulerAnglesYXZ(); local rotacionSnap = math.round(y / (math.pi/2)) * (math.pi/2)
        return CFrame.Angles(0, rotacionSnap, 0)
    end
    return CFrame.new()
end

-- ==========================================
-- ✈️ SISTEMA DE MOVIMIENTO (DEL SCRIPT 2)
-- ==========================================
local function volarHacia(destino)
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local destinoFinal = destino
    local distancia = (root.Position - destinoFinal).Magnitude
    
    if distancia > 2 then -- Pequeño umbral para evitar tweens micro
        local tiempo = distancia / VELOCIDAD_VUELO
        
        -- Creamos el Tween tal cual el Script 2
        local tweenInfo = TweenInfo.new(tiempo, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(destinoFinal)})
        
        root.Anchored = false 
        root.Velocity = Vector3.zero
        tween:Play()
        tween.Completed:Wait()
    end
    
    -- Aseguramos posición final
    root.Velocity = Vector3.zero
    root.CFrame = CFrame.new(destinoFinal)
    root.Anchored = true 
end

-- ==========================================
-- 🏗️ CONSTRUCCIÓN V42
-- ==========================================
function construirV42()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona destino") end
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    
    local character = LocalPlayer.Character
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    procesoActivo = true
    notificar("🚀 Construyendo (Modo Vuelo)...")

    local rotacionDeseada = obtenerRotacionJugador()
    local nuevoCentroCFrame = CFrame.new(bloqueSeleccionado.Position) * rotacionDeseada
    local posOriginalPlayer = hrp.CFrame
    
    -- Anclaje inicial
    hrp.Anchored = true 

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end

        -- 1. Cálculos
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        local nombreBloque = data.Type or "part_cube"

        -- 2. Visualizador
        local ghost = Instance.new("Part"); ghost.Name = "Ghost_Visual"; ghost.Size = sizeObjetivo; ghost.CFrame = cframeFinal
        ghost.Color = Color3.new(unpack(data.Color or {0.5,0.5,0.5})); ghost.Material = Enum.Material[data.Mat or "Plastic"]
        ghost.Transparency = TRANSPARENCIA_MOLDE; ghost.Anchored = true; ghost.CanCollide = false; ghost.Parent = workspace
        table.insert(fantasmasCreados, ghost)

        -- 3. MOVIMIENTO (SISTEMA INTEGRADO DEL SCRIPT 2)
        -- Calculamos posición objetivo (5 studs arriba del bloque)
        local objetivoMovimiento = cframeFinal.Position + Vector3.new(0, 5, 0)
        volarHacia(objetivoMovimiento)
        
        -- 4. BUCLE DE PERSISTENCIA
        local bloqueConfirmado = false
        local intentos = 0
        
        while not bloqueConfirmado and intentos < 5 do
            intentos = intentos + 1
            local _, idCheck = encontrarBloqueYSuID(cframeFinal)
            
            if not idCheck then
                PlotSystem:InvokeServer("placeFurniture", nombreBloque, cframeFinal)
                
                local esperaID = 0
                local nuevoID = nil
                while not nuevoID and esperaID < 15 do
                    task.wait(0.05)
                    _, nuevoID = encontrarBloqueYSuID(cframeFinal)
                    esperaID = esperaID + 1
                end
                
                if nuevoID then
                    PlotSystem:InvokeServer("scaleFurniture", nuevoID, cframeFinal, sizeObjetivo)
                    task.wait(0.6)
                    
                    local _, checkFinal = encontrarBloqueYSuID(cframeFinal)
                    if checkFinal then
                        bloqueConfirmado = true
                    else
                        notificar("⚠️ Reintentando bloque " .. i)
                        task.wait(0.2)
                    end
                else
                    task.wait(0.2)
                end
            else
                bloqueConfirmado = true
            end
        end
        
        task.wait(0.05)
    end

    procesoActivo = false
    hrp.Anchored = false 
    hrp.CFrame = posOriginalPlayer 
    notificar("✅ Terminado")
    task.delay(4, function() limpiarFantasmas() end)
end

-- ==========================================
-- 🎯 COPIAR
-- ==========================================
function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona centro") end
    datosGuardados = {}
    local origen = bloqueSeleccionado.CFrame
    
    local function esValido(p)
        if not p:IsA("BasePart") or p.Name == "Baseplate" or p.Name:find("Ghost") or p.Parent:FindFirstChild("Humanoid") then return false end
        local distH = (Vector3.new(p.Position.X, 0, p.Position.Z) - Vector3.new(origen.Position.X, 0, origen.Position.Z)).Magnitude
        local distV = p.Position.Y - origen.Position.Y
        return distH <= RADIO_HORIZONTAL and distV >= -2 and distV <= ALTURA_MAXIMA
    end

    local visual = Instance.new("Part"); visual.Shape = Enum.PartType.Cylinder; visual.Size = Vector3.new(1, RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2) 
    visual.CFrame = origen * CFrame.Angles(0,0,math.rad(90)) + Vector3.new(0, 5, 0); visual.Transparency = 0.9; visual.Color = Color3.fromRGB(255, 255, 0); visual.Anchored = true; visual.CanCollide = false; visual.Parent = workspace; Debris:AddItem(visual, 2)

    local c = 0
    for _, p in pairs(workspace:GetDescendants()) do
        if esValido(p) and p ~= visual then
            local rel = origen:Inverse() * p.CFrame
            table.insert(datosGuardados, {Type = obtenerNombreReal(p), Size = {p.Size.X, p.Size.Y, p.Size.Z}, CF = {rel:GetComponents()}, Color = {p.Color.R, p.Color.G, p.Color.B}, Mat = p.Material.Name})
            c = c + 1
        end
    end
    notificar("✅ Copiados: " .. c)
end

function limpiarFantasmas() for _, p in pairs(fantasmasCreados) do if p then p:Destroy() end end; fantasmasCreados = {} end
function vaciarMemoria() datosGuardados = {}; notificar("♻️ Memoria vacía") end
function detenerProceso() procesoActivo = false; if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.Anchored = false end; notificar("🛑 Parando...") end

-- GUI Actions
function actualizarListaArchivos()
    for _, child in pairs(scrollList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local s, a = pcall(function() return listfiles(CARPETA_PRINCIPAL) end)
    if not s then return end
    for _, r in pairs(a) do
        local n = r:match("([^/]+)$")
        if n:sub(-5)==".json" then
            local f = Instance.new("Frame", scrollList); f.Size=UDim2.new(1,0,0,25); f.BackgroundTransparency=1
            local b = Instance.new("TextButton", f); b.Text=n:sub(1,-6); b.Size=UDim2.new(0.75,0,1,0); b.BackgroundColor3=Color3.fromRGB(60,60,60); b.TextColor3=Color3.new(1,1,1)
            b.MouseButton1Click:Connect(function() datosGuardados=HttpService:JSONDecode(readfile(r)); notificar("📂 "..#datosGuardados.." items") end)
            local d = Instance.new("TextButton", f); d.Text="X"; d.Size=UDim2.new(0.2,0,1,0); d.Position=UDim2.new(0.8,0,0,0); d.BackgroundColor3=Color3.fromRGB(150,0,0); d.TextColor3=Color3.new(1,1,1)
            d.MouseButton1Click:Connect(function() delfile(r); actualizarListaArchivos() end)
        end
    end
    scrollList.CanvasSize = UDim2.new(0,0,0,layoutFiles.AbsoluteContentSize.Y)
end

btnSave.MouseButton1Click:Connect(function() if #datosGuardados>0 and nameInput.Text~="" then writefile(CARPETA_PRINCIPAL.."/"..nameInput.Text..".json", HttpService:JSONEncode(datosGuardados)); notificar("💾 Guardado"); actualizarListaArchivos() end end)

local function crearBoton(t, c, o, f) local b = Instance.new("TextButton"); b.Text = t; b.Size = UDim2.new(1, 0, 0, 32); b.BackgroundColor3 = c; b.TextColor3 = Color3.new(1,1,1); b.LayoutOrder = o; b.Parent = actionsFrame; Instance.new("UICorner", b); b.MouseButton1Click:Connect(f) end
crearBoton("🎯 1. COPIAR (K)", Color3.fromRGB(0, 150, 100), 1, copiarEstructura)
crearBoton("🏗️ 2. CONSTRUIR (B)", Color3.fromRGB(0, 120, 200), 2, construirV42)
crearBoton("🛑 PARAR (X)", Color3.fromRGB(200, 50, 50), 3, detenerProceso)
crearBoton("♻️ VACIAR MEMORIA (Z)", Color3.fromRGB(80, 80, 80), 4, vaciarMemoria)
crearBoton("🗑️ LIMPIAR GHOSTS", Color3.fromRGB(50, 50, 50), 5, limpiarFantasmas)

tool.Equipped:Connect(function(mouse) actualizarListaArchivos(); mouse.Button1Down:Connect(function() if mouse.Target then bloqueSeleccionado = mouse.Target; highlightBox.Adornee = bloqueSeleccionado; notificar("🎯 Centro: " .. bloqueSeleccionado.Name) end end); mouse.KeyDown:Connect(function(key) if key=="k" then copiarEstructura() elseif key=="b" then construirV42() elseif key=="x" then detenerProceso() elseif key=="z" then vaciarMemoria() end end) end)
tool.Unequipped:Connect(function() highlightBox.Adornee = nil; bloqueSeleccionado = nil end)
actualizarListaArchivos()
notificar("✅ V42: Vuelo Suave (Tween) Activado")
