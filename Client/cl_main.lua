local QBCore = exports['arabcodingteam-core']:GetCoreObject()
local pGang = {}
local pJob = {}
local IsBlocking = false

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local Data = QBCore.Functions.GetPlayerData()
    pGang = Data.gang
    pJob = Data.job
    createBlips(pJob.name)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function()
    local Data = QBCore.Functions.GetPlayerData()
    pJob = Data.job
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    pGang = gang
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    pJob = job
end)

RegisterNetEvent('arabcodingteam-garages:client:houseGarageConfig', function(garageConfig)
    TriggerServerEvent('arabcodingteam-garages:server:houseGarageConfig', garageConfig)
    HouseGarages = garageConfig
end)

RegisterNetEvent('arabcodingteam-garages:client:addHouseGarage', function(house, garageInfo)
    TriggerServerEvent('arabcodingteam-garages:server:addHouseGarage', house, garageInfo)
    HouseGarages[house] = garageInfo
end)

RegisterNetEvent('Garages:Open', function()
    IsBlocking = false
    local pGarage = GetCurrentGarage()
    if pGarage ~= nil then
        TriggerEvent('arabcodingteam-garages:VehicleList')
    else
        pGarage = GetJobGarage()
        if pGarage ~= nil then
            if pJob.name == JobGarages[pGarage].job then
                TriggerEvent('arabcodingteam-garages:OpenJobGarage', pGarage)
            else
                QBCore.Functions.Notify("You are not Authorized!", "error", 3000)
            end
        else
            pGarage = GetGangGarage()
            if pGarage ~= nil then
                if pGang.name == GangGarages[pGarage].gang then
                    TriggerEvent('arabcodingteam-garages:VehicleList')
                else
                    QBCore.Functions.Notify("How do you even think about it bitch?", "error", 3000)
                end
            else
                QBCore.Functions.Notify("We couldn't Find Garage Sir!", "error", 3000)
            end
        end
    end
end)

RegisterNetEvent('Garages:OpenHouseGarage', function()
    local pGarage = GetHouseGarage()
    if pGarage ~= nil then
        QBCore.Functions.TriggerCallback("arabcodingteam-houses:server:hasKey", function(result)
            if result then
                TriggerEvent('arabcodingteam-garages:HouseVehicleList')
            else
                QBCore.Functions.Notify("You have no Access to the Garage!", "error", 3000)
            end
        end, pGarage)
    else
        QBCore.Functions.Notify("We couldn't Find Garage here Sir!", "error", 3000)
    end
end)

RegisterNetEvent('arabcodingteam-garages:OpenJobGarage', function()
    local pGarage = GetJobGarage()
    if JobGarages[pGarage].isHelipad then
        if pJob.onduty then
            TriggerEvent('arabcodingteam-garages:client:SharedHeliGarage')
        else
            TriggerEvent('QBCore:Notify', "Shared Garages can be accessed only when in Onduty!", "error")
        end
    else
        local pSpot = GetpSpot(pGarage)
        if pSpot ~= nil then
               exports['arabcodingteam-menu']:openMenu({
                {
                    header = "Personal Vehicles",
                    txt = "List of owned vehicles.",
                    params = {
                        event = "arabcodingteam-garages:JobVehicleList",
                    }
                },
                {
                    header = "Shared Vehicles",
                    txt = "List of shared vehicles.",
                    params = {
                        event = "arabcodingteam-garages:client:SharedVehicleMenu"
                    }
                },
                {
                    header = "< Close Menu",
                    params = {
                        event = "",
                    }
                },
            })
        else
            QBCore.Functions.Notify("You need to be near a free parking spot!")
        end
    end
end)

RegisterNetEvent('Garages:OpenDepot', function()
    local pDepot = GetCurrentDepot()
       exports['arabcodingteam-menu']:openMenu({
        {
			header = Depots[pDepot].label,
			isMenuHeader = true
		},
		{
			header = "My Vehicles",
			txt = "List of my depoted vehicles.",
			params = {
				event = "arabcodingteam-garages:client:DepotVehicleList",
			}
		},
		{
			header = "< Close Menu",
			params = {
				event = "",
			}
		},
    })
end)

RegisterNetEvent('Garages:Store', function()
    local ped = PlayerPedId()
    local coordA = GetEntityCoords(ped, 1)
    local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 100.0, 0.0)
    local curVeh = getVehicleInDirection(coordA, coordB)
    local plate = GetVehicleNumberPlateText(curVeh)
    local bodyDamage = math.ceil(GetVehicleBodyHealth(curVeh))
    local engineDamage = math.ceil(GetVehicleEngineHealth(curVeh))
    local vehmods = QBCore.Functions.GetVehicleProperties(curVeh)
    local totalFuel = exports['LegacyFuel']:GetFuel(curVeh)
    QBCore.Functions.TriggerCallback('arabcodingteam-garage:server:checkVehicleOwner', function(owned)
        Citizen.Wait(1000)
        if owned then
            local pGarage = GetCurrentGarage()
            if pGarage ~= nil then
                TriggerServerEvent('arabcodingteam-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, pGarage)
                TriggerServerEvent('arabcodingteam-garage:server:updateVehicleState', 1, plate, pGarage)
                TriggerServerEvent('arabcodingteam-garages:server:SaveVehicleMods', plate, vehmods)
                RemoveOutsideVeh(plate)
                QBCore.Functions.DeleteVehicle(curVeh)
                QBCore.Functions.Notify("Vehicle Parked In : "..Garages[pGarage].label, "success", 44)
            else
                pGarage = GetJobGarage()
                if pGarage ~= nil then
                    if JobGarages[pGarage].isHelipad then
                        QBCore.Functions.Notify("This vehicle can not be stored!", "error", 3000)
                    else
                        if pJob.name == JobGarages[pGarage].job then
                            TriggerServerEvent('arabcodingteam-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, pGarage)
                            TriggerServerEvent('arabcodingteam-garage:server:updateVehicleState', 1, plate, pGarage)
                            TriggerServerEvent('arabcodingteam-garages:server:SaveVehicleMods', plate, vehmods)
                            RemoveOutsideVeh(plate)
                            QBCore.Functions.DeleteVehicle(curVeh)
                            QBCore.Functions.Notify("Vehicle Parked In : "..JobGarages[pGarage].label, "success", 4500)
                        else
                            QBCore.Functions.Notify("You Have No Acceess to Park here!", "error", 3000)
                        end
                    end
                else
                    pGarage = GetGangGarage()
                    if pGarage ~= nil then
                        if pGang.name == GangGarages[pGarage].gang then
                            TriggerServerEvent('arabcodingteam-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, pGarage)
                            TriggerServerEvent('arabcodingteam-garage:server:updateVehicleState', 1, plate, pGarage)
                            TriggerServerEvent('arabcodingteam-garages:server:SaveVehicleMods', plate, vehmods)
                            RemoveOutsideVeh(plate)
                            QBCore.Functions.DeleteVehicle(curVeh)
                            QBCore.Functions.Notify("Vehicle Parked In : "..GangGarages[pGarage].label, "success", 4500)
                        else
                            QBCore.Functions.Notify("You can't store your shit here Bitch!", "error", 3000)
                        end
                    else
                        QBCore.Functions.Notify("Unable to Find Garage", "error", 3000)
                    end
                end
            end
        else
            local pGarage = GetJobGarage()
            QBCore.Functions.TriggerCallback('arabcodingteam-garage:server:isSharedVehicle', function(isShared)
                if isShared then
                    if pJob.name == JobGarages[pGarage].job then
                        TriggerServerEvent('arabcodingteam-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, pGarage, true)
                        TriggerServerEvent('arabcodingteam-garage:server:updateSharedVehState', 'Stored', plate, pGarage)
                        TriggerServerEvent('arabcodingteam-garages:server:SaveVehicleMods', plate, vehmods, true)
                        QBCore.Functions.DeleteVehicle(curVeh)
                    else
                        QBCore.Functions.Notify("You are not Authorized!", "error", 3000)
                    end
                else
                    QBCore.Functions.Notify("This vehicle can not be stored!", "error", 3500)
                end
            end, plate, pGarage)
        end
    end, plate)
end)

RegisterNetEvent('Garages:StoreInHouseGarage', function()
    local ped = PlayerPedId()
    local coordA = GetEntityCoords(ped, 1)
    local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 100.0, 0.0)
    local curVeh = getVehicleInDirection(coordA, coordB)
    local plate = GetVehicleNumberPlateText(curVeh)
    local bodyDamage = math.ceil(GetVehicleBodyHealth(curVeh))
    local engineDamage = math.ceil(GetVehicleEngineHealth(curVeh))
    local totalFuel = exports['LegacyFuel']:GetFuel(curVeh)
    QBCore.Functions.TriggerCallback('arabcodingteam-garage:server:checkVehicleOwner', function(owned)
        Citizen.Wait(1000)
        if owned then
            local pGarage = GetHouseGarage()
            if pGarage ~= nil then
                QBCore.Functions.TriggerCallback("arabcodingteam-houses:server:hasKey", function(result)
                    if result then
                        TriggerServerEvent('arabcodingteam-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, pGarage)
                        TriggerServerEvent('arabcodingteam-garage:server:updateVehicleState', 1, plate, pGarage)
                        RemoveOutsideVeh(plate)
                        QBCore.Functions.DeleteVehicle(curVeh)
                        QBCore.Functions.Notify("Vehicle Parked In : "..HouseGarages[pGarage].label, "success", 4500)
                    else
                        QBCore.Functions.Notify("You have no Access to park here!", "error", 3000)
                    end
                end, pGarage)
            else
                QBCore.Functions.Notify("Unable to Find Garage", "error", 3000)
            end
        end
    end, plate)
end)

RegisterNetEvent('arabcodingteam-garages:VehicleList', function()
    DeleteViewedCar()
    local pGarage = GetCurrentGarage()
    if pGarage ~= nil then
        pGarage = pGarage
    else
        pGarage = GetGangGarage()
        if pGarage ~= nil then
            pGarage = pGarage
        else
            pGarage = GetJobGarage()
        end
    end
    local pSpot = GetpSpot(pGarage)
    QBCore.Functions.TriggerCallback('arabcodingteam-garages:server:GetPlayerVehicles', function(vehcheck)
        if vehcheck ~= nil then
            if pSpot ~= nil then
                local state = nil
                local isLocked = false
                local menu = {{
                    header = "< Close Menu",
                    params = {
                        event = "",       
                    },
                }}
                for i = 1, #vehcheck do
                    if vehcheck[i].state == 1 then
                        state = "Stored"
                    elseif vehcheck[i].state == 2 then
                        state = "Impounded"
                    elseif vehcheck[i].state == 0 then
                        state = "Out"
                    end
                    if vehcheck[i].state == 1 then
                        isLocked = false
                    else
                        isLocked = true
                    end
                    table.insert(menu, {
                        header = QBCore.Shared.Vehicles[vehcheck[i].vehicle].name,
                        txt = "Plate: "..vehcheck[i].plate.." | "..state,
                        isMenuHeader = isLocked,
                        params = {
                            event = "arabcodingteam-garages:client:AttemptSpawn",
                            args = {
                                plate = vehcheck[i].plate,
                                vehicle = vehcheck[i].vehicle,
                                engine = vehcheck[i].engine,
                                body = vehcheck[i].body,
                                fuel = vehcheck[i].fuel,
                                vehstate = state,
                                garage = pGarage,
                                type = 0
                            }
                        }
                    })
                    exports['arabcodingteam-menu']:openMenu(menu)
                end
            else
                QBCore.Functions.Notify("You need to be near a free parking spot!")
            end
        else
            TriggerEvent('QBCore:Notify', "You Have No Vehicles Parked here!", "error")
        end
    end, pGarage)
end)

RegisterNetEvent('arabcodingteam-garages:HouseVehicleList', function(Data)
    DeleteViewedCar()
    local pGarage = GetHouseGarage()
    QBCore.Functions.TriggerCallback('arabcodingteam-garages:server:GetPlayerVehicles', function(vehcheck)
        if vehcheck ~= nil then
            local state = nil
            local isLocked = false
            local menu = {{
                header = "< Close Menu",
                params = {
                    event = "",       
                }
            }}
            for i = 1, #vehcheck do
                if vehcheck[i].state == 1 then
                    state = "Stored"
                elseif vehcheck[i].state == 2 then
                    state = "Impounded"
                elseif vehcheck[i].state == 0 then
                    state = "Out"
                end
                if vehcheck[i].state == 1 then
                    isLocked = false
                else
                    isLocked = true
                end
                table.insert(menu, {
                    header = QBCore.Shared.Vehicles[vehcheck[i].vehicle].name,
                    txt = "Plate: "..vehcheck[i].plate.." | "..state,
                    isMenuHeader = isLocked,
                    params = {
                        event = "arabcodingteam-garages:client:AttemptHouseSpawn",
                        args = {
                            plate = vehcheck[i].plate,
                            vehicle = vehcheck[i].vehicle,
                            engine = vehcheck[i].engine,
                            body = vehcheck[i].body,
                            fuel = vehcheck[i].fuel,
                            vehstate = state,
                            garage = pGarage
                        }
                    }
                })
                exports['arabcodingteam-menu']:openMenu( menu)
            end
        else
            TriggerEvent('QBCore:Notify', "You Have No Vehicles Parked in Garage!", "error")
        end
    end, pGarage)
end)

RegisterNetEvent('arabcodingteam-garages:JobVehicleList', function()
    DeleteViewedCar()
    local pGarage = GetCurrentGarage()
    if pGarage ~= nil then
        pGarage = pGarage
    else
        pGarage = GetGangGarage()
        if pGarage ~= nil then
            pGarage = pGarage
        else
            pGarage = GetJobGarage()
        end
    end
    local pSpot = GetpSpot(pGarage)
    QBCore.Functions.TriggerCallback('arabcodingteam-garages:server:GetPlayerVehicles', function(vehcheck)
        if vehcheck ~= nil then
            if pSpot ~= nil then
                local state = nil
                local isLocked = false
                local menu = {{
                    header = "< Go Back",
                    params = {
                        event = "arabcodingteam-garages:OpenJobGarage",       
                    },
                }}
                for i = 1, #vehcheck do
                    if vehcheck[i].state == 1 then
                        state = "Stored"
                    elseif vehcheck[i].state == 2 then
                        state = "Impounded"
                    elseif vehcheck[i].state == 0 then
                        state = "Out"
                    end
                    if vehcheck[i].state == 1 then
                        isLocked = false
                    else
                        isLocked = true
                    end
                    table.insert(menu, {
                        header = QBCore.Shared.Vehicles[vehcheck[i].vehicle].name,
                        txt = "Plate: "..vehcheck[i].plate.." | "..state,
                        isMenuHeader = isLocked,
                        params = {
                            event = "arabcodingteam-garages:client:AttemptSpawn",
                            args = {
                                plate = vehcheck[i].plate,
                                vehicle = vehcheck[i].vehicle,
                                engine = vehcheck[i].engine,
                                body = vehcheck[i].body,
                                fuel = vehcheck[i].fuel,
                                vehstate = state,
                                garage = pGarage,
                                type = 1
                            }
                        }
                    })
                    exports['arabcodingteam-menu']:openMenu( menu)
                end
            else
                QBCore.Functions.Notify("You need to be near a free parking spot!")
            end
        else
            TriggerEvent('QBCore:Notify', "You Have No Vehicles Parked here!", "error")
        end
    end, pGarage)
end)

RegisterNetEvent('arabcodingteam-garages:client:DepotVehicleList', function()
    QBCore.Functions.TriggerCallback('arabcodingteam-garages:server:GetDepotVehicles', function(vehcheck)
        local NoVeh = false
        local menu = {{
            header = "< Go Back",
            params = {
                event = "Garages:OpenDepot",
            }
        }}
        for i = 1, #vehcheck do
            if vehcheck[i].state == 0 then
                table.insert(menu, {
                    header = QBCore.Shared.Vehicles[vehcheck[i].vehicle].name,
                    txt = "Plate: "..vehcheck[i].plate.." | Fine: "..vehcheck[i].depotprice.."$",
                    params = {
                        event = "arabcodingteam-garages:client:SpawnDepotVehicle",
                        args = {
                            plate = vehcheck[i].plate,
                            vehicle = vehcheck[i].vehicle,
                            engine = vehcheck[i].engine,
                            body = vehcheck[i].body,
                            fuel = vehcheck[i].fuel,
                            fine = vehcheck[i].depotprice,
                            garage = vehcheck[i].garage
                        }
                    }
                })
                NoVeh = true
            end
            if NoVeh then
                exports['arabcodingteam-menu']:openMenu( menu)
            end
        end
        if not NoVeh then
            TriggerEvent('QBCore:Notify', "You Have No Vehicles in Depot!", "error", 3000)
        end
    end)
end)

RegisterNetEvent('arabcodingteam-garages:client:SharedVehicleMenu', function()
    local garage = GetJobGarage()
    if pJob.onduty then
        QBCore.Functions.TriggerCallback('arabcodingteam-garage:server:CheckSharedCategories', function(result)
            if result ~= nil then
                local categories = {}
                for i = 1, #result do
                    if categories[result[i].category] == nil then
                        categories[result[i].category] = 1
                    else
                        categories[result[i].category] = tonumber(categories[result[i].category]) + 1
                    end
                end
                local menu = {{
                    header = "< Go Back",
                    params = {
                    event = "arabcodingteam-garages:OpenJobGarage",
                    },
                }}
                for k, v in pairs(categories) do
                    table.insert(menu, {
                        header = k,
                        txt = v.." vehicles.",
                        params = {
                            event = "arabcodingteam-garages:client:SharedVehicleList",
                            args = {
                                cat = k
                            }
                        },
                    })
                end
                exports['arabcodingteam-menu']:openMenu( menu)
            else
                TriggerEvent('QBCore:Notify', "No Vehicles!", "error")
            end
        end, garage)
    else
        TriggerEvent('QBCore:Notify', "Shared Garages can be accessed only when in Onduty!", "error")
    end
end)

RegisterNetEvent('arabcodingteam-garages:client:SharedHeliGarage', function()
    DeleteViewedCar()
    local pGarage = GetJobGarage()
    QBCore.Functions.TriggerCallback('arabcodingteam-garages:server:GetSharedHeli', function(vehcheck)
        if vehcheck ~= nil then
            local isLocked = false
            local menu = {{
                header = "< Close Menu",
                params = {
                    event = "",
                }
            }}
            for i = 1, #vehcheck do
                table.insert(menu, {
                    header = QBCore.Shared.Vehicles[vehcheck[i].vehicle].name,
                    txt = "Plate: "..vehcheck[i].plate.." | "..vehcheck[i].state,
                    params = {
                        event = "arabcodingteam-garages:client:AttemptSpawn",
                        args = {
                            plate = vehcheck[i].plate,
                            vehicle = vehcheck[i].vehicle,
                            engine = vehcheck[i].engine,
                            body = vehcheck[i].body,
                            fuel = vehcheck[i].fuel,
                            vehstate = vehcheck[i].state,
                            garage = pGarage,
                            type = 3
                        }
                    }
                })
                exports['arabcodingteam-menu']:openMenu( menu)
            end
        else
            TriggerEvent('QBCore:Notify', "No Vehicles!", "error")
        end
    end, pGarage)
end)

RegisterNetEvent('arabcodingteam-garages:client:SharedVehicleList', function(Data)
    DeleteViewedCar()
    local pGarage = GetJobGarage()
    QBCore.Functions.TriggerCallback('arabcodingteam-garages:server:GetSharedVehicles', function(vehcheck)
        if vehcheck ~= nil then
            local isLocked = false
            local menu = {{
                header = "< Go Back",
                params = {
                    event = "arabcodingteam-garages:client:SharedVehicleMenu",
                }
            }}
            for i = 1, #vehcheck do
                table.insert(menu, {
                    header = QBCore.Shared.Vehicles[vehcheck[i].vehicle].name,
                    txt = "Plate: "..vehcheck[i].plate.." | "..vehcheck[i].state,
                    params = {
                        event = "arabcodingteam-garages:client:AttemptSpawn",
                        args = {
                            plate = vehcheck[i].plate,
                            vehicle = vehcheck[i].vehicle,
                            engine = vehcheck[i].engine,
                            body = vehcheck[i].body,
                            fuel = vehcheck[i].fuel,
                            vehstate = vehcheck[i].state,
                            cat = Data.cat,
                            garage = pGarage,
                            type = 2
                        }
                    }
                })
                exports['arabcodingteam-menu']:openMenu( menu)
            end
        else
            TriggerEvent('QBCore:Notify', "You Have No Vehicles Parked here!", "error")
        end
    end, pGarage, Data.cat)
end)

RegisterNetEvent('arabcodingteam-garages:client:AttemptSpawn', function(Data)
    local enginePercent = round(Data.engine / 10, 0)
	local bodyPercent = round(Data.body / 10, 0)
    if Data.type == 0 then
           exports['arabcodingteam-menu']:openMenu({
            {
                header = "< Go Back",
                params = {
                    event = "arabcodingteam-garages:VehicleList"
                }
            },
            {
                header = "Take Out Vehicle",
                params = {
                    event = "arabcodingteam-garages:client:SpawnVehicle",
                    args = {
                        vehicle = Data.vehicle,
                        garage  = Data.garage,
                        fuel = Data.fuel,
                        body = Data.body,
                        engine = Data.engine,
                        plate = Data.plate,
                        gType = 0
                    }
                }
                
            },
            {
                header = "Vehicle Status",
                isMenuHeader = true,
                txt = Data.vehstate.." | Engine: "..enginePercent.."% | Body: "..bodyPercent.."%"
            },
        })
        SpawnVehicle(Data.vehicle, Data.garage, Data.fuel, Data.body, Data.engine, Data.plate, 0)
    elseif Data.type == 1 then
           exports['arabcodingteam-menu']:openMenu({
            {
                header = "< Go Back",
                params = {
                    event = "arabcodingteam-garages:JobVehicleList"
                }
            },
            {
                header = "Take Out Vehicle",
                params = {
                    event = "arabcodingteam-garages:client:SpawnVehicle",
                    args = {
                        vehicle = Data.vehicle,
                        garage  = Data.garage,
                        fuel = Data.fuel,
                        body = Data.body,
                        engine = Data.engine,
                        plate = Data.plate,
                        gType = 0
                    }
                }
                
            },
            {
                header = "Vehicle Status",
                isMenuHeader = true,
                txt = Data.vehstate.." | Engine: "..enginePercent.."% | Body: "..bodyPercent.."%"
            },
        })
        SpawnVehicle(Data.vehicle, Data.garage, Data.fuel, Data.body, Data.engine, Data.plate, 0)
    elseif Data.type == 2 then
        local isLocked = false
        if Data.vehstate == "Out" then
            isLocked = true
        end
           exports['arabcodingteam-menu']:openMenu({
            {
                header = "< Go Back",
                params = {
                    event = "arabcodingteam-garages:client:SharedVehicleList",
                    args = {
                        cat = Data.cat
                    }
                }
            },
            {
                header = "Take Out Vehicle",
                isMenuHeader = isLocked,
                params = {
                    event = "arabcodingteam-garages:client:SpawnVehicle",
                    args = {
                        vehicle = Data.vehicle,
                        garage  = Data.garage,
                        fuel = Data.fuel,
                        body = Data.body,
                        engine = Data.engine,
                        plate = Data.plate,
                        isShared = true,
                        gType = 0
                    }
                }
                
            },
            {
                header = "Vehicle Status",
                isMenuHeader = true,
                txt = Data.vehstate.." | Engine: "..enginePercent.."% | Body: "..bodyPercent.."%"
            },
            {
                header = "Vehicle Parking Log",
                params = {
                    event = "arabcodingteam-garages:client:ParkingLog",
                    args = {
                        plate = Data.plate,
                        vehicle = Data.vehicle,
                        engine = Data.engine,
                        body = Data.body,
                        fuel = Data.fuel,
                        vehstate = Data.state,
                        garage = Data.garage,
                        state = Data.vehstate,
                        cat = Data.cat
                    }
                }
            },
        })
        if Data.isBack == nil then
            if not isLocked then
                SpawnVehicle(Data.vehicle, Data.garage, Data.fuel, Data.body, Data.engine, Data.plate, 0, false, true)
            end
        end
    elseif Data.type == 3 then
        local isLocked = false
        if Data.vehstate == "Out" then
            isLocked = true
        end
           exports['arabcodingteam-menu']:openMenu({
            {
                header = "< Go Back",
                params = {
                    event = "arabcodingteam-garages:client:SharedHeliGarage"
                },
            },
            {
                header = "Take Out Vehicle",
                isMenuHeader = isLocked,
                params = {
                    event = "arabcodingteam-garages:client:SpawnVehicle",
                    args = {
                        vehicle = Data.vehicle,
                        garage  = Data.garage,
                        fuel = Data.fuel,
                        body = Data.body,
                        engine = Data.engine,
                        plate = Data.plate,
                        isShared = true,
                        gType = 2
                    }
                }
                
            },
            {
                header = "Vehicle Status",
                isMenuHeader = true,
                txt = Data.vehstate.." | Engine: "..enginePercent.."% | Body: "..bodyPercent.."%"
            },
            {
                header = "Vehicle Parking Log",
                params = {
                    event = "arabcodingteam-garages:client:ParkingLog",
                    args = {
                        plate = Data.plate,
                        vehicle = Data.vehicle,
                        engine = Data.engine,
                        body = Data.body,
                        fuel = Data.fuel,
                        vehstate = Data.state,
                        garage = Data.garage,
                        state = Data.vehstate,
                        isHeli = true
                    }
                }
            },
        })
        if Data.isBack == nil then
            if not isLocked then
                SpawnVehicle(Data.vehicle, Data.garage, Data.fuel, Data.body, Data.engine, Data.plate, 2, false, true)
            end
        end
    end
end)

RegisterNetEvent('arabcodingteam-garages:client:AttemptHouseSpawn', function(Data)
    local enginePercent = round(Data.engine / 10, 0)
	local bodyPercent = round(Data.body / 10, 0)
       exports['arabcodingteam-menu']:openMenu({
        {
			header = "< Go Back",
			params = {
				event = "arabcodingteam-garages:HouseVehicleList"
			}
		},
		{
			header = "Take Out Vehicle",
			params = {
				event = "arabcodingteam-garages:client:SpawnVehicle",
				args = {
                    vehicle = Data.vehicle,
                    garage  = Data.garage,
                    fuel = Data.fuel,
                    body = Data.body,
                    engine = Data.engine,
                    plate = Data.plate,
                    gType = 1
                }
			}
			
		},
		{
			header = "Vehicle Status",
            isMenuHeader = true,
			txt = Data.vehstate.." | Engine: "..enginePercent.."% | Body: "..bodyPercent.."%"
		},
    })
    SpawnVehicle(Data.vehicle, Data.garage, Data.fuel, Data.body, Data.engine, Data.plate, 1)
end)

RegisterNetEvent('arabcodingteam-garages:client:SpawnVehicle', function(Data)
    SpawnVehicle(Data.vehicle, Data.garage, Data.fuel, Data.body, Data.engine, Data.plate, Data.gType, true, Data.isShared)
    if Data.isShared then
        TriggerServerEvent('arabcodingteam-garages:server:UpdateParkingLog', Data.plate)
    end
end)

RegisterNetEvent('arabcodingteam-garages:client:SpawnDepotVehicle', function(Data)
    SpawnDepotVehicle(Data)
end)

RegisterNetEvent('arabcodingteam-garages:client:ParkingLog', function(Data)
    if Data.isHeli then
        vtype = 3
    else
        vtype = 2
    end
    local menu = {{
        header = "< Go Back",
        params = {
            event = "arabcodingteam-garages:client:AttemptSpawn",
            args = {
                plate = Data.plate,
                vehicle = Data.vehicle,
                engine = Data.engine,
                body = Data.body,
                fuel = Data.fuel,
                vehstate = Data.state,
                garage = Data.garage,
                vehstate = Data.state,
                cat = Data.cat,
                isBack = 2,
                type = vtype
            }
        }
    }}
    QBCore.Functions.TriggerCallback('arabcodingteam-garage:server:GetParkingLog', function(plog)
        if plog ~= nil then
            for i = 1, #plog do
                table.insert(menu, {
                    header = tostring(plog[i].id).." | "..tostring(plog[i].time),
                    txt = tostring(plog[i].name).." ("..tostring(plog[i].post)..")",
                    isMenuHeader = true
                })
            end
        end
        exports['arabcodingteam-menu']:openMenu( menu)
    end, Data.plate)
end)

RegisterNetEvent('arabcodingteam-garages:client:AddSharedVehicle', function(garage, faction, category)
    if JobGarages[garage] ~= nil then
        local ped = PlayerPedId()
        local coordA = GetEntityCoords(ped, 1)
        local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 100.0, 0.0)
        local curVeh = getVehicleInDirection(coordA, coordB)
        local vehhash = GetEntityModel(curVeh)
        local plate = GetVehicleNumberPlateText(curVeh)
        local model = nil
        for k, v in pairs(QBCore.Shared.Vehicles) do
            if vehhash == QBCore.Shared.Vehicles[k].hash then
                model = QBCore.Shared.Vehicles[k].model
                break
            end
        end
        if curVeh ~= 0 then
            if model ~= nil then
                QBCore.Functions.TriggerCallback('arabcodingteam-garage:server:isVehicleOwned', function(owned)
                    if owned then
                        QBCore.Functions.Notify("You Can't save player owned vehicles!", "error")
                    else
                        QBCore.Functions.TriggerCallback('arabcodingteam-garage:server:isVehicleShared', function(shared)
                            if shared then
                                QBCore.Functions.Notify("This Vehicle is already a Shared Vehicles!", "error")
                            else
                                local mods = json.encode(QBCore.Functions.GetVehicleProperties(curVeh))
                                TriggerServerEvent('arabcodingteam-garages:server:SaveSharedVehicle', plate, model, category, vehhash, faction, garage, mods)
                                Wait(100)
                                QBCore.Functions.DeleteVehicle(curVeh)
                                QBCore.Functions.Notify("Vehicle plate: "..plate.." is stored in "..JobGarages[garage].label, "success")
                            end
                        end, plate)
                    end
                end, plate)
            else
                print("THIS VEHICLE MUST BE ADDED TO THE SHARED.LUA")
            end
        else
            QBCore.Functions.Notify("You need to look at a vehicle to store!", "error")
        end
    else
        QBCore.Functions.Notify("Shared Garage must be exist!", "error")
    end
end)

RegisterNetEvent('garages:Blips')
AddEventHandler('garages:Blips', function()
    ToggleGarageBlips()
end)

CreateThread(function()
    Wait(2000)
    while true do
        Wait(500)
        for k, v in pairs(HouseGarages) do
            if HouseGarages[k].takeVehicle.x ~= nil and HouseGarages[k].takeVehicle.y ~= nil and HouseGarages[k].takeVehicle.z ~= nil then
                if #(GetEntityCoords(PlayerPedId()) - vector3(HouseGarages[k].takeVehicle.x, HouseGarages[k].takeVehicle.y, HouseGarages[k].takeVehicle.z)) < 5 then
                    TriggerEvent('cd_drawtextui:ShowUI', 'show', "Parking")
                    SetTimeout(500, function()
                        TriggerEvent('cd_drawtextui:HideUI')
                    end)
                end
            end
        end
    end
end)
