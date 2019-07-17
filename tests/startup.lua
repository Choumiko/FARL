local round = require("lib_control").round
local startup = {}

function startup.init(test, i, surface)
    local case = test.cases[i]
    local rid, sid = case.rail, case.signal
    case.e_rail = test.created_entities.rails[rid] or false
    case.e_signal = test.created_entities.signals[sid] or false
    local loco = surface.create_entity(case.loco)
    if loco and round(loco.orientation, 2) ~= round(case.loco.orientation, 2) then
        loco.rotate()
    end
    case.locomotive = loco
end

startup[1] = {
    name = "Test1",
    test_type = "",
    to_create = {
        rails = {
            [100009799999107] = {direction = 7, force = "player", name = "straight-rail", position = {x = 97, y = -9}},
            [100009299999405] = {direction = 5, force = "player", name = "curved-rail", position = {x = 92, y = -6}},
            [100009599999307] = {direction = 7, force = "player", name = "straight-rail", position = {x = 95, y = -7}},
            [100009599999103] = {direction = 3, force = "player", name = "straight-rail", position = {x = 95, y = -9}},
            [100009399999507] = {direction = 7, force = "player", name = "straight-rail", position = {x = 93, y = -5}},
            [100009399999303] = {direction = 3, force = "player", name = "straight-rail", position = {x = 93, y = -7}},
            [100009299999606] = {direction = 6, force = "player", name = "curved-rail", position = {x = 92, y = -4}},
            [100009199999707] = {direction = 7, force = "player", name = "straight-rail", position = {x = 91, y = -3}},
            [100009199999503] = {direction = 3, force = "player", name = "straight-rail", position = {x = 91, y = -5}},
            [100009799999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 97, y = -5}},
            [100009999999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 99, y = -5}},
            [100010199999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 101, y = -5}},
            [100008700000002] = {direction = 2, force = "player", name = "curved-rail", position = {x = 86, y = 0}},
            [100008999999703] = {direction = 3, force = "player", name = "straight-rail", position = {x = 89, y = -3}},
            [100007600000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 75, y = 1}},
            [100007800000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 77, y = 1}},
            [100008000000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 79, y = 1}},
            [100008200000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 81, y = 1}},
            [100008400000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 83, y = 1}},
            [100008600000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 85, y = 1}},
            [100008800000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 87, y = 1}},
            [100009000000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 89, y = 1}},
            [100009200000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 91, y = 1}},
            [100009400000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 93, y = 1}},
            [100009600000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 95, y = 1}},
            [100009800000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 97, y = 1}},
            [100010000000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 99, y = 1}},
            [100010200000102] = {direction = 2, force = "player", name = "straight-rail", position = {x = 101, y = 1}}
        },
        signals = {
            [100009249999050] = {direction = 0, force = "player", name = "rail-signal", position = {x = 91.5, y = -9.5}},
            [100008949999651] = {direction = 1, force = "player", name = "rail-signal", position = {x = 88.5, y = -3.5}},
            [100009149999855] = {direction = 5, force = "player", name = "rail-signal", position = {x = 90.5, y = -1.5}},
            [100009849999952] = {direction = 2, force = "player", name = "rail-signal", position = {x = 97.5, y = -0.5}}
        }
    },
    cases = {
        {
            loco = {force = "player", name = "farl", orientation = 0.125, position = {x = 90.91015625, y = -3.91015625}},
            rail = 100009799999107,
            signal = 100009149999855
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.75, position = {x = 92.28125, y = 1}},
            rail = 100007600000102,
            signal = 100008949999651
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.75, position = {x = 97.78125, y = -5}},
            rail = false,
            signal = false
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.25, position = {x = 78.78125, y = 1}},
            rail = 100010200000102,
            signal = false
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.15494085848330998, position = {x = 87.25390625, y = -0.7890625}},
            rail = 100009799999107,
            signal = 100009149999855
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.033104654401541, position = {x = 92.58984375, y = -7.98046875}},
            rail = 100009299999405,
            signal = 100009149999855
        }
    }
}

startup[2] = {
    name = "Test2",
    test_type = "",
    to_create = {
        rails = {
            [100010399999307] = {direction = 7, force = "player", name = "straight-rail", position = {x = 103, y = -7}},
            [100010199999507] = {direction = 7, force = "player", name = "straight-rail", position = {x = 101, y = -5}},
            [100010199999303] = {direction = 3, force = "player", name = "straight-rail", position = {x = 101, y = -7}},
            [100009699999802] = {direction = 2, force = "player", name = "curved-rail", position = {x = 96, y = -2}},
            [100009999999503] = {direction = 3, force = "player", name = "straight-rail", position = {x = 99, y = -5}},
            [100007999999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 79, y = -1}},
            [100008199999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 81, y = -1}},
            [100008399999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 83, y = -1}},
            [100008599999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 85, y = -1}},
            [100008799999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 87, y = -1}},
            [100008999999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 89, y = -1}},
            [100009199999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 91, y = -1}},
            [100009399999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 93, y = -1}},
            [100009599999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 95, y = -1}},
            [100010100000003] = {direction = 3, force = "player", name = "curved-rail", position = {x = 100, y = 0}},
            [100009799999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 97, y = -1}},
            [100009999999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 99, y = -1}},
            [100010199999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 101, y = -1}},
            [100010399999902] = {direction = 2, force = "player", name = "straight-rail", position = {x = 103, y = -1}},
            [100010400000301] = {direction = 1, force = "player", name = "straight-rail", position = {x = 103, y = 3}},
            [100010600000305] = {direction = 5, force = "player", name = "straight-rail", position = {x = 105, y = 3}},
            [100010600000501] = {direction = 1, force = "player", name = "straight-rail", position = {x = 105, y = 5}}
        },
        signals = {
            [100009949999451] = {direction = 1, force = "player", name = "rail-signal", position = {x = 98.5, y = -5.5}},
            [100008050000056] = {direction = 6, force = "player", name = "rail-signal", position = {x = 79.5, y = 0.5}},
            [100009350000056] = {direction = 6, force = "player", name = "rail-signal", position = {x = 92.5, y = 0.5}}
        }
    },
    cases = {
        {
            loco = {force = "player", name = "farl", orientation = 0.25, position = {x = 83.5, y = -1}},
            rail = 100010399999902,
            signal = 100009350000056
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.75, position = {x = 93.9375, y = -1}},
            rail = 100007999999902,
            signal = 100009949999451
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.125, position = {x = 100.88671875, y = -5.88671875}},
            rail = 100010399999307,
            signal = 100009350000056
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.36673533916472998, position = {x = 102.6875, y = 1.8359375}},
            rail = 100010600000501,
            signal = 100009350000056
        }
    }
}

startup[3] = {
    name = "Test3",
    test_type = "",
    to_create = {
        rails = {
            [100008599998300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -17}},
            [100009199998300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -17}},
            [100009799998300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -17}},
            [100008599998500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -15}},
            [100009199998500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -15}},
            [100009799998500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -15}},
            [100008799998705] = {direction = 5, force = "player", name = "straight-rail", position = {x = 87, y = -13}},
            [100008599998700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -13}},
            [100008799998901] = {direction = 1, force = "player", name = "straight-rail", position = {x = 87, y = -11}},
            [100009199998700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -13}},
            [100009799998700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -13}},
            [100008599998900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -11}},
            [100008999998905] = {direction = 5, force = "player", name = "straight-rail", position = {x = 89, y = -11}},
            [100008999999101] = {direction = 1, force = "player", name = "straight-rail", position = {x = 89, y = -9}},
            [100009299999204] = {direction = 4, force = "player", name = "curved-rail", position = {x = 92, y = -8}},
            [100009799998900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -11}},
            [100008699999404] = {direction = 4, force = "player", name = "curved-rail", position = {x = 86, y = -6}},
            [100008599999100] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -9}},
            [100009099999203] = {direction = 3, force = "player", name = "curved-rail", position = {x = 90, y = -8}},
            [100009199999105] = {direction = 5, force = "player", name = "straight-rail", position = {x = 91, y = -9}},
            [100009199999301] = {direction = 1, force = "player", name = "straight-rail", position = {x = 91, y = -7}},
            [100009799999100] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -9}},
            [100008599999300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -7}},
            [100009399999305] = {direction = 5, force = "player", name = "straight-rail", position = {x = 93, y = -7}},
            [100009399999501] = {direction = 1, force = "player", name = "straight-rail", position = {x = 93, y = -5}},
            [100009799999300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -7}},
            [100008599999500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -5}},
            [100009699999800] = {direction = 0, force = "player", name = "curved-rail", position = {x = 96, y = -2}},
            [100009799999500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -5}},
            [100008599999700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -3}},
            [100009100000000] = {direction = 0, force = "player", name = "curved-rail", position = {x = 90, y = 0}},
            [100008999999705] = {direction = 5, force = "player", name = "straight-rail", position = {x = 89, y = -3}},
            [100009300000007] = {direction = 7, force = "player", name = "curved-rail", position = {x = 92, y = 0}},
            [100008999999901] = {direction = 1, force = "player", name = "straight-rail", position = {x = 89, y = -1}},
            [100009799999700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -3}},
            [100008599999900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = -1}},
            [100009199999905] = {direction = 5, force = "player", name = "straight-rail", position = {x = 91, y = -1}},
            [100009200000101] = {direction = 1, force = "player", name = "straight-rail", position = {x = 91, y = 1}},
            [100009799999900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = -1}},
            [100008600000100] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = 1}},
            [100009400000105] = {direction = 5, force = "player", name = "straight-rail", position = {x = 93, y = 1}},
            [100009400000301] = {direction = 1, force = "player", name = "straight-rail", position = {x = 93, y = 3}},
            [100009800000100] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = 1}},
            [100008600000300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = 3}},
            [100009600000305] = {direction = 5, force = "player", name = "straight-rail", position = {x = 95, y = 3}},
            [100009600000501] = {direction = 1, force = "player", name = "straight-rail", position = {x = 95, y = 5}},
            [100009800000300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = 3}},
            [100008600000500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = 5}},
            [100009200000500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = 5}},
            [100009800000500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = 5}},
            [100008600000700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = 7}},
            [100009200000700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = 7}},
            [100009800000700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = 7}},
            [100008600000900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 85, y = 9}},
            [100009200000900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = 9}},
            [100009800000900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 97, y = 9}}
        },
        signals = {
            [100009349998254] = {direction = 4, force = "player", name = "rail-signal", position = {x = 92.5, y = -17.5}},
            [100009649998650] = {direction = 0, force = "player", name = "rail-signal", position = {x = 95.5, y = -13.5}},
            [100008749999256] = {direction = 6, force = "player", name = "rail-signal", position = {x = 86.5, y = -7.5}},
            [100009549999353] = {direction = 3, force = "player", name = "rail-signal", position = {x = 94.5, y = -6.5}},
            [100009349999557] = {direction = 7, force = "player", name = "rail-signal", position = {x = 92.5, y = -4.5}},
            [100009049999653] = {direction = 3, force = "player", name = "rail-signal", position = {x = 89.5, y = -3.5}},
            [100008849999857] = {direction = 7, force = "player", name = "rail-signal", position = {x = 87.5, y = -1.5}},
            [100009649999952] = {direction = 2, force = "player", name = "rail-signal", position = {x = 95.5, y = -0.5}},
            [100008750000554] = {direction = 4, force = "player", name = "rail-signal", position = {x = 86.5, y = 5.5}},
            [100009050000950] = {direction = 0, force = "player", name = "rail-signal", position = {x = 89.5, y = 9.5}}
        }
    },
    cases = {
        {
            loco = {force = "player", name = "farl", orientation = 0, position = {x = 85, y = 1.78125}},
            rail = 100008599998300,
            signal = 100009049999653
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.5, position = {x = 91, y = 5.90625}},
            rail = 100009200000900,
            signal = 100009050000950
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.31355601549148999, position = {x = 92.328125, y = 0.0703125}},
            rail = 100009300000007,
            signal = 100008849999857
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.5, position = {x = 97, y = -9.78125}},
            rail = 100009800000900,
            signal = 100009349999557
        },
        {
            loco = {force = "player", name = "farl", orientation = 0, position = {x = 91, y = -14.4375}},
            rail = 100009199998300,
            signal = 100009349998254
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.875, position = {x = 87.421875, y = -11.578125}},
            rail = 100008799998705,
            signal = 100009549999353
        }
    }
}

startup[4] = {
    name = "Test4",
    test_type = "",
    to_create = {
        rails = {
            [100010199998507] = {direction = 7, force = "player", name = "straight-rail", position = {x = 101, y = -15}},
            [100008399998505] = {direction = 5, force = "player", name = "straight-rail", position = {x = 83, y = -15}},
            [100008399998701] = {direction = 1, force = "player", name = "straight-rail", position = {x = 83, y = -13}},
            [100009199998500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -15}},
            [100009999998707] = {direction = 7, force = "player", name = "straight-rail", position = {x = 99, y = -13}},
            [100009999998503] = {direction = 3, force = "player", name = "straight-rail", position = {x = 99, y = -15}},
            [100008599998705] = {direction = 5, force = "player", name = "straight-rail", position = {x = 85, y = -13}},
            [100008599998901] = {direction = 1, force = "player", name = "straight-rail", position = {x = 85, y = -11}},
            [100009199998700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -13}},
            [100009799998907] = {direction = 7, force = "player", name = "straight-rail", position = {x = 97, y = -11}},
            [100009799998703] = {direction = 3, force = "player", name = "straight-rail", position = {x = 97, y = -13}},
            [100008799998905] = {direction = 5, force = "player", name = "straight-rail", position = {x = 87, y = -11}},
            [100008799999101] = {direction = 1, force = "player", name = "straight-rail", position = {x = 87, y = -9}},
            [100009199998900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -11}},
            [100009599999107] = {direction = 7, force = "player", name = "straight-rail", position = {x = 95, y = -9}},
            [100009599998903] = {direction = 3, force = "player", name = "straight-rail", position = {x = 95, y = -11}},
            [100008999999105] = {direction = 5, force = "player", name = "straight-rail", position = {x = 89, y = -9}},
            [100009199999100] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -9}},
            [100009399999103] = {direction = 3, force = "player", name = "straight-rail", position = {x = 93, y = -9}},
            [100009199999300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -7}},
            [100008199999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 81, y = -5}},
            [100008399999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 83, y = -5}},
            [100008599999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 85, y = -5}},
            [100008799999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 87, y = -5}},
            [100008999999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 89, y = -5}},
            [100009199999500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -5}},
            [100009199999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 91, y = -5}},
            [100009399999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 93, y = -5}},
            [100009599999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 95, y = -5}},
            [100009799999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 97, y = -5}},
            [100009999999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 99, y = -5}},
            [100010199999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 101, y = -5}},
            [100010399999502] = {direction = 2, force = "player", name = "straight-rail", position = {x = 103, y = -5}},
            [100008799999907] = {direction = 7, force = "player", name = "straight-rail", position = {x = 87, y = -1}},
            [100009199999700] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -3}},
            [100009599999705] = {direction = 5, force = "player", name = "straight-rail", position = {x = 95, y = -3}},
            [100009599999901] = {direction = 1, force = "player", name = "straight-rail", position = {x = 95, y = -1}},
            [100008600000107] = {direction = 7, force = "player", name = "straight-rail", position = {x = 85, y = 1}},
            [100008599999903] = {direction = 3, force = "player", name = "straight-rail", position = {x = 85, y = -1}},
            [100009199999900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = -1}},
            [100009799999905] = {direction = 5, force = "player", name = "straight-rail", position = {x = 97, y = -1}},
            [100009800000101] = {direction = 1, force = "player", name = "straight-rail", position = {x = 97, y = 1}},
            [100008400000307] = {direction = 7, force = "player", name = "straight-rail", position = {x = 83, y = 3}},
            [100008400000103] = {direction = 3, force = "player", name = "straight-rail", position = {x = 83, y = 1}},
            [100009200000100] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = 1}},
            [100010000000105] = {direction = 5, force = "player", name = "straight-rail", position = {x = 99, y = 1}},
            [100010000000301] = {direction = 1, force = "player", name = "straight-rail", position = {x = 99, y = 3}},
            [100008200000507] = {direction = 7, force = "player", name = "straight-rail", position = {x = 81, y = 5}},
            [100008200000303] = {direction = 3, force = "player", name = "straight-rail", position = {x = 81, y = 3}},
            [100009200000300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = 3}},
            [100010200000305] = {direction = 5, force = "player", name = "straight-rail", position = {x = 101, y = 3}},
            [100010200000501] = {direction = 1, force = "player", name = "straight-rail", position = {x = 101, y = 5}},
            [100009200000500] = {direction = 0, force = "player", name = "straight-rail", position = {x = 91, y = 5}}
        },
        signals = {
            [100008749998753] = {direction = 3, force = "player", name = "rail-signal", position = {x = 86.5, y = -12.5}},
            [100009849998955] = {direction = 5, force = "player", name = "rail-signal", position = {x = 97.5, y = -10.5}},
            [100008749999352] = {direction = 2, force = "player", name = "rail-signal", position = {x = 86.5, y = -6.5}},
            [100008749999656] = {direction = 6, force = "player", name = "rail-signal", position = {x = 86.5, y = -3.5}},
            [100009049999656] = {direction = 6, force = "player", name = "rail-signal", position = {x = 89.5, y = -3.5}},
            [100009049999750] = {direction = 0, force = "player", name = "rail-signal", position = {x = 89.5, y = -2.5}},
            [100009349999754] = {direction = 4, force = "player", name = "rail-signal", position = {x = 92.5, y = -2.5}},
            [100008449999951] = {direction = 1, force = "player", name = "rail-signal", position = {x = 83.5, y = -0.5}},
            [100009650000057] = {direction = 7, force = "player", name = "rail-signal", position = {x = 95.5, y = 0.5}}
        }
    },
    cases = {
        {
            loco = {force = "player", name = "farl", orientation = 0.625, position = {x = 84.65234375, y = 0.34375}},
            rail = 100008200000507,
            signal = 100008449999951
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.5, position = {x = 91, y = 0}},
            rail = 100009200000500,
            signal = 100009049999750
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.375, position = {x = 96.6953125, y = -0.30078125}},
            rail = 100010200000501,
            signal = 100009650000057
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.25, position = {x = 96.6875, y = -5}},
            rail = 100010399999502,
            signal = 100009049999656
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.125, position = {x = 95.9765625, y = -10.9765625}},
            rail = 100010199998507,
            signal = 100009849998955
        },
        {
            loco = {force = "player", name = "farl", orientation = 0, position = {x = 91, y = -10.8125}},
            rail = 100009199998500,
            signal = 100009349999754
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.875, position = {x = 85.5390625, y = -11.4609375}},
            rail = 100008399998505,
            signal = 100008749998753
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.75, position = {x = 86.84375, y = -5}},
            rail = 100008199999502,
            signal = 100008749999352
        }
    }
}

startup[5] = {
    name = "Test5",
    test_type = "",
    to_create = {
        rails = {
            [100009699999003] = {direction = 3, force = "player", name = "curved-rail", position = {x = 96, y = -10}},
            [100009999999301] = {direction = 1, force = "player", name = "straight-rail", position = {x = 99, y = -7}},
            [100009099999403] = {direction = 3, force = "player", name = "curved-rail", position = {x = 90, y = -6}},
            [100009799999302] = {direction = 2, force = "player", name = "straight-rail", position = {x = 97, y = -7}},
            [100010199999305] = {direction = 5, force = "player", name = "straight-rail", position = {x = 101, y = -7}},
            [100009999999302] = {direction = 2, force = "player", name = "straight-rail", position = {x = 99, y = -7}},
            [100010199999501] = {direction = 1, force = "player", name = "straight-rail", position = {x = 101, y = -5}},
            [100010199999302] = {direction = 2, force = "player", name = "straight-rail", position = {x = 101, y = -7}},
            [100008699999805] = {direction = 5, force = "player", name = "curved-rail", position = {x = 86, y = -2}},
            [100009399999701] = {direction = 1, force = "player", name = "straight-rail", position = {x = 93, y = -3}},
            [100009199999702] = {direction = 2, force = "player", name = "straight-rail", position = {x = 91, y = -3}},
            [100009599999705] = {direction = 5, force = "player", name = "straight-rail", position = {x = 95, y = -3}},
            [100009399999702] = {direction = 2, force = "player", name = "straight-rail", position = {x = 93, y = -3}},
            [100009599999901] = {direction = 1, force = "player", name = "straight-rail", position = {x = 95, y = -1}},
            [100009599999702] = {direction = 2, force = "player", name = "straight-rail", position = {x = 95, y = -3}},
            [100008399999900] = {direction = 0, force = "player", name = "straight-rail", position = {x = 83, y = -1}},
            [100008400000307] = {direction = 7, force = "player", name = "straight-rail", position = {x = 83, y = 3}},
            [100008400000103] = {direction = 3, force = "player", name = "straight-rail", position = {x = 83, y = 1}},
            [100008400000100] = {direction = 0, force = "player", name = "straight-rail", position = {x = 83, y = 1}},
            [100008200000303] = {direction = 3, force = "player", name = "straight-rail", position = {x = 81, y = 3}},
            [100008400000300] = {direction = 0, force = "player", name = "straight-rail", position = {x = 83, y = 3}}
        },
        signals = {}
    },
    cases = {
        {
            loco = {force = "player", name = "farl", orientation = 0.043625678867102007, position = {x = 86.44140625, y = -3.390625}},
            rail = 100008699999805
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.87489002943038994, position = {x = 94.01953125, y = -2.9765625}},
            rail = false
        },
        {
            loco = {force = "player", name = "farl", orientation = 0.81748497486114999, position = {x = 95.88671875, y = -9.9765625}},
            rail = 100009699999003
        }
    }
}

startup[6] = {
    name = "Test6",
    test_type = "",
    to_create = {
        rails = {
            [100008799998105] = {name = "straight-rail", position = {x = 87, y = -19}, direction = 5, force = "player"},
            [100008799998301] = {name = "straight-rail", position = {x = 87, y = -17}, direction = 1, force = "player"},
            [100009599998307] = {name = "straight-rail", position = {x = 95, y = -17}, direction = 7, force = "player"},
            [100009599998103] = {name = "straight-rail", position = {x = 95, y = -19}, direction = 3, force = "player"},
            [100009099998600] = {name = "curved-rail", position = {x = 90, y = -14}, direction = 0, force = "player"},
            [100009299998601] = {name = "curved-rail", position = {x = 92, y = -14}, direction = 1, force = "player"},
            [100007999998901] = {name = "straight-rail", position = {x = 79, y = -11}, direction = 1, force = "player"},
            [100010399998907] = {name = "straight-rail", position = {x = 103, y = -11}, direction = 7, force = "player"},
            [100008199998905] = {name = "straight-rail", position = {x = 81, y = -11}, direction = 5, force = "player"},
            [100008499999207] = {name = "curved-rail", position = {x = 84, y = -8}, direction = 7, force = "player"},
            [100009899999202] = {name = "curved-rail", position = {x = 98, y = -8}, direction = 2, force = "player"},
            [100010199998903] = {name = "straight-rail", position = {x = 101, y = -11}, direction = 3, force = "player"},
            [100008499999406] = {name = "curved-rail", position = {x = 84, y = -6}, direction = 6, force = "player"},
            [100009899999403] = {name = "curved-rail", position = {x = 98, y = -6}, direction = 3, force = "player"},
            [100008199999707] = {name = "straight-rail", position = {x = 81, y = -3}, direction = 7, force = "player"},
            [100010199999701] = {name = "straight-rail", position = {x = 101, y = -3}, direction = 1, force = "player"},
            [100007999999907] = {name = "straight-rail", position = {x = 79, y = -1}, direction = 7, force = "player"},
            [100007999999703] = {name = "straight-rail", position = {x = 79, y = -3}, direction = 3, force = "player"},
            [100009100000005] = {name = "curved-rail", position = {x = 90, y = 0}, direction = 5, force = "player"},
            [100009300000004] = {name = "curved-rail", position = {x = 92, y = 0}, direction = 4, force = "player"},
            [100010399999705] = {name = "straight-rail", position = {x = 103, y = -3}, direction = 5, force = "player"},
            [100008800000507] = {name = "straight-rail", position = {x = 87, y = 5}, direction = 7, force = "player"},
            [100008800000303] = {name = "straight-rail", position = {x = 87, y = 3}, direction = 3, force = "player"},
            [100009600000305] = {name = "straight-rail", position = {x = 95, y = 3}, direction = 5, force = "player"},
            [100009600000501] = {name = "straight-rail", position = {x = 95, y = 5}, direction = 1, force = "player"}
        },
        signals = {}
    },
    cases = {
        {loco = {name = "farl", position = {x = 89.921875, y = 0.01171875}, orientation = 0.5699, force = "player"}, rail = 100008800000507, signal = false},
        {loco = {name = "farl", position = {x = 83.6328125, y = -8.25390625}, orientation = 0.8267, force = "player"}, rail = 100007999998901, signal = false},
        {loco = {name = "farl", position = {x = 92.5234375, y = -14.84375}, orientation = 0.0864, force = "player"}, rail = 100009599998103, signal = false},
        {loco = {name = "farl", position = {x = 98.06640625, y = -5.89453125}, orientation = 0.321, force = "player"}, rail = 100010399999705, signal = false},
        {loco = {name = "farl", position = {x = 88.5, y = -16.26171875}, orientation = 0.8885, force = "player"}, rail = 100008799998105, signal = false},
        {loco = {name = "farl", position = {x = 81.8203125, y = -4.5625}, orientation = 0.6396, force = "player"}, rail = 100007999999907, signal = false},
        {loco = {name = "farl", position = {x = 92.4765625, y = 0.765625}, orientation = 0.4151, force = "player"}, rail = 100009600000501, signal = false},
        {loco = {name = "farl", position = {x = 99.69921875, y = -9.08984375}, orientation = 0.1471, force = "player"}, rail = 100010399998907, signal = false},
        {loco = {name = "farl", position = {x = 81.8203125, y = -4.5625}, orientation = 0.1396, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 92.4765625, y = 0.765625}, orientation = 0.9151, force = "player"}, rail = 100009300000004, signal = false},
        {loco = {name = "farl", position = {x = 100.47265625, y = -9.6640625}, orientation = 0.6357, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 88.5, y = -16.26171875}, orientation = 0.3885, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 81.44140625, y = -9.7265625}, orientation = 0.3653, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 88.5078125, y = 2.25}, orientation = 0.1114, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 100.40625, y = -4.38671875}, orientation = 0.8634, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 93.76171875, y = -16.59765625}, orientation = 0.6157, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 82.40234375, y = -9.015625}, orientation = 0.3511, force = "player"}, rail = 100008499999207, signal = false},
        {loco = {name = "farl", position = {x = 89.66015625, y = 0.515625}, orientation = 0.0799, force = "player"}, rail = 100009100000005, signal = false},
        {loco = {name = "farl", position = {x = 99.33203125, y = -5.16015625}, orientation = 0.8467, force = "player"}, rail = 100009899999403, signal = false},
        {loco = {name = "farl", position = {x = 92.7734375, y = -15.23046875}, orientation = 0.5944, force = "player"}, rail = 100009299998601, signal = false}
    }
}

startup[7] = {
    name = "Test7",
    test_type = "",
    to_create = {
        rails = {
            [100008799998707] = {name = "straight-rail", position = {x = 87, y = -13}, direction = 7, force = "player"},
            [100008799998503] = {name = "straight-rail", position = {x = 87, y = -15}, direction = 3, force = "player"},
            [100008599998907] = {name = "straight-rail", position = {x = 85, y = -11}, direction = 7, force = "player"},
            [100008599998703] = {name = "straight-rail", position = {x = 85, y = -13}, direction = 3, force = "player"},
            [100008299999201] = {name = "curved-rail", position = {x = 82, y = -8}, direction = 1, force = "player"},
            [100007799999302] = {name = "straight-rail", position = {x = 77, y = -7}, direction = 2, force = "player"},
            [100007999999302] = {name = "straight-rail", position = {x = 79, y = -7}, direction = 2, force = "player"},
            [100008199999302] = {name = "straight-rail", position = {x = 81, y = -7}, direction = 2, force = "player"},
            [100008699999403] = {name = "curved-rail", position = {x = 86, y = -6}, direction = 3, force = "player"},
            [100008999999701] = {name = "straight-rail", position = {x = 89, y = -3}, direction = 1, force = "player"},
            [100008199999700] = {name = "straight-rail", position = {x = 81, y = -3}, direction = 0, force = "player"},
            [100008799999702] = {name = "straight-rail", position = {x = 87, y = -3}, direction = 2, force = "player"},
            [100009199999705] = {name = "straight-rail", position = {x = 91, y = -3}, direction = 5, force = "player"},
            [100008999999702] = {name = "straight-rail", position = {x = 89, y = -3}, direction = 2, force = "player"},
            [100009199999901] = {name = "straight-rail", position = {x = 91, y = -1}, direction = 1, force = "player"},
            [100009199999702] = {name = "straight-rail", position = {x = 91, y = -3}, direction = 2, force = "player"},
            [100009599999907] = {name = "straight-rail", position = {x = 95, y = -1}, direction = 7, force = "player"},
            [100009399999702] = {name = "straight-rail", position = {x = 93, y = -3}, direction = 2, force = "player"},
            [100009599999702] = {name = "straight-rail", position = {x = 95, y = -3}, direction = 2, force = "player"},
            [100009799999702] = {name = "straight-rail", position = {x = 97, y = -3}, direction = 2, force = "player"},
            [100009999999702] = {name = "straight-rail", position = {x = 99, y = -3}, direction = 2, force = "player"},
            [100010199999702] = {name = "straight-rail", position = {x = 101, y = -3}, direction = 2, force = "player"},
            [100010399999702] = {name = "straight-rail", position = {x = 103, y = -3}, direction = 2, force = "player"},
            [100010599999702] = {name = "straight-rail", position = {x = 105, y = -3}, direction = 2, force = "player"},
            [100010799999702] = {name = "straight-rail", position = {x = 107, y = -3}, direction = 2, force = "player"},
            [100008199999900] = {name = "straight-rail", position = {x = 81, y = -1}, direction = 0, force = "player"},
            [100009400000107] = {name = "straight-rail", position = {x = 93, y = 1}, direction = 7, force = "player"},
            [100009399999903] = {name = "straight-rail", position = {x = 93, y = -1}, direction = 3, force = "player"},
            [100008200000102] = {name = "straight-rail", position = {x = 81, y = 1}, direction = 2, force = "player"},
            [100008200000100] = {name = "straight-rail", position = {x = 81, y = 1}, direction = 0, force = "player"},
            [100008400000102] = {name = "straight-rail", position = {x = 83, y = 1}, direction = 2, force = "player"},
            [100008600000102] = {name = "straight-rail", position = {x = 85, y = 1}, direction = 2, force = "player"},
            [100008800000102] = {name = "straight-rail", position = {x = 87, y = 1}, direction = 2, force = "player"},
            [100009200000307] = {name = "straight-rail", position = {x = 91, y = 3}, direction = 7, force = "player"},
            [100009000000102] = {name = "straight-rail", position = {x = 89, y = 1}, direction = 2, force = "player"},
            [100009200000102] = {name = "straight-rail", position = {x = 91, y = 1}, direction = 2, force = "player"},
            [100009200000103] = {name = "straight-rail", position = {x = 91, y = 1}, direction = 3, force = "player"},
            [100009400000102] = {name = "straight-rail", position = {x = 93, y = 1}, direction = 2, force = "player"},
            [100009600000102] = {name = "straight-rail", position = {x = 95, y = 1}, direction = 2, force = "player"},
            [100009800000102] = {name = "straight-rail", position = {x = 97, y = 1}, direction = 2, force = "player"},
            [100010000000102] = {name = "straight-rail", position = {x = 99, y = 1}, direction = 2, force = "player"},
            [100010200000102] = {name = "straight-rail", position = {x = 101, y = 1}, direction = 2, force = "player"},
            [100010400000102] = {name = "straight-rail", position = {x = 103, y = 1}, direction = 2, force = "player"},
            [100010600000102] = {name = "straight-rail", position = {x = 105, y = 1}, direction = 2, force = "player"},
            [100010800000102] = {name = "straight-rail", position = {x = 107, y = 1}, direction = 2, force = "player"},
            [100008200000300] = {name = "straight-rail", position = {x = 81, y = 3}, direction = 0, force = "player"}
        },
        signals = {
            [100010249999552] = {name = "rail-signal", position = {x = 101.5, y = -4.5}, direction = 2, force = "player"},
            [100010849999552] = {name = "rail-signal", position = {x = 107.5, y = -4.5}, direction = 2, force = "player"},
            [100010249999856] = {name = "rail-signal", position = {x = 101.5, y = -1.5}, direction = 6, force = "player"},
            [100010849999856] = {name = "rail-signal", position = {x = 107.5, y = -1.5}, direction = 6, force = "player"},
            [100008550000256] = {name = "rail-signal", position = {x = 84.5, y = 2.5}, direction = 6, force = "player"}
        }
    },
    cases = {
        {loco = {name = "farl", position = {x = 97.90625, y = -3}, orientation = 0.75, force = "player"}, rail = 100008799999702, signal = 100010249999552},
        {loco = {name = "farl", position = {x = 86.34375, y = -13.34375}, orientation = 0.625, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 78.1875, y = -7}, orientation = 0.25, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 81, y = 2}, orientation = 0, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 89.53125, y = -3.4375}, orientation = 0.8734, force = "player"}, rail = false, signal = "some error"},
        {loco = {name = "farl", position = {x = 88.21875, y = 1}, orientation = 0.25, force = "player"}, rail = 100010800000102, signal = 100008550000256}
    }
}

startup[8] = {
    name = "Test8",
    test_type = "",
    to_create = {
        rails = {
            [100010399998707] = {name = "straight-rail", position = {x = 103, y = -13}, direction = 7, force = "player"},
            [100010399998503] = {name = "straight-rail", position = {x = 103, y = -15}, direction = 3, force = "player"},
            [100010199998907] = {name = "straight-rail", position = {x = 101, y = -11}, direction = 7, force = "player"},
            [100010199998703] = {name = "straight-rail", position = {x = 101, y = -13}, direction = 3, force = "player"},
            [100010099999006] = {name = "curved-rail", position = {x = 100, y = -10}, direction = 6, force = "player"},
            [100009999999107] = {name = "straight-rail", position = {x = 99, y = -9}, direction = 7, force = "player"},
            [100009999998903] = {name = "straight-rail", position = {x = 99, y = -11}, direction = 3, force = "player"},
            [100010599998902] = {name = "straight-rail", position = {x = 105, y = -11}, direction = 2, force = "player"},
            [100010799998902] = {name = "straight-rail", position = {x = 107, y = -11}, direction = 2, force = "player"},
            [100009499999402] = {name = "curved-rail", position = {x = 94, y = -6}, direction = 2, force = "player"},
            [100009799999103] = {name = "straight-rail", position = {x = 97, y = -9}, direction = 3, force = "player"},
            [100007999999502] = {name = "straight-rail", position = {x = 79, y = -5}, direction = 2, force = "player"},
            [100008199999502] = {name = "straight-rail", position = {x = 81, y = -5}, direction = 2, force = "player"},
            [100008399999502] = {name = "straight-rail", position = {x = 83, y = -5}, direction = 2, force = "player"},
            [100008599999502] = {name = "straight-rail", position = {x = 85, y = -5}, direction = 2, force = "player"},
            [100008799999502] = {name = "straight-rail", position = {x = 87, y = -5}, direction = 2, force = "player"},
            [100008999999502] = {name = "straight-rail", position = {x = 89, y = -5}, direction = 2, force = "player"},
            [100009499999603] = {name = "curved-rail", position = {x = 94, y = -4}, direction = 3, force = "player"},
            [100009799999901] = {name = "straight-rail", position = {x = 97, y = -1}, direction = 1, force = "player"},
            [100009999999905] = {name = "straight-rail", position = {x = 99, y = -1}, direction = 5, force = "player"},
            [100010000000101] = {name = "straight-rail", position = {x = 99, y = 1}, direction = 1, force = "player"},
            [100010200000105] = {name = "straight-rail", position = {x = 101, y = 1}, direction = 5, force = "player"}
        },
        signals = {
            [100010349998451] = {name = "rail-signal", position = {x = 102.5, y = -15.5}, direction = 1, force = "player"},
            [100010749998752] = {name = "rail-signal", position = {x = 106.5, y = -12.5}, direction = 2, force = "player"},
            [100009849999653] = {name = "rail-signal", position = {x = 97.5, y = -3.5}, direction = 3, force = "player"}
        }
    },
    cases = {
        {loco = {name = "farl", position = {x = 87.28125, y = -5}, orientation = 0.75, force = "player"}, rail = 100007999999502, signal = 100009849999653},
        {loco = {name = "farl", position = {x = 94.05859375, y = -6.1015625}, orientation = 0.6791, force = "player"}, rail = 100007999999502, signal = 100009849999653},
        {loco = {name = "farl", position = {x = 93.078125, y = -5.703125}, orientation = 0.1977, force = "player"}, rail = 100010399998503, signal = false},
        {loco = {name = "farl", position = {x = 93.24609375, y = -4.234375}, orientation = 0.3055, force = "player"}, rail = 100010200000105, signal = false},
        {loco = {name = "farl", position = {x = 100.32421875, y = -10.0703125}, orientation = 0.1866, force = "player"}, rail = 100010799998902, signal = false},
        {loco = {name = "farl", position = {x = 82.25, y = -5}, orientation = 0.75, force = "player"}, rail = 100007999999502, signal = 100009849999653}
    }
}

return startup
