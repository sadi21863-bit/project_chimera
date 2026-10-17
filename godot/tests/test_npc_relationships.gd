extends SceneTree

func _init():
    var passed := 0
    var failed := 0

    # Test 1: Load NPCRelationships script
    var script = load("res://autoload/npc_relationships.gd")
    if script:
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Could not load NPCRelationships script")
        failed += 1

    # Test 2: Initialize relationships
    var npc_rels = script.new()
    npc_rels.reset()  # Reset to clear any saved data
    
    if npc_rels.relationships.has("alex"):
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Relationships not initialized for alex")
        failed += 1

    # Test 3: Get base values
    var trust = npc_rels.get_trust("alex")
    if trust == 0.5:
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Base trust should be 0.5, got ", trust)
        failed += 1

    # Test 4: Modify trust
    npc_rels.modify_trust("alex", 0.2)
    trust = npc_rels.get_trust("alex")
    if trust == 0.7:
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Trust should be 0.7 after +0.2, got ", trust)
        failed += 1

    # Test 5: Modify suspicion
    npc_rels.modify_suspicion("alex", 0.3)
    var suspicion = npc_rels.get_suspicion("alex")
    if suspicion == 0.6:
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Suspicion should be 0.6 after +0.3, got ", suspicion)
        failed += 1

    # Test 6: Relationship summary (suspicion 0.6 should be Friendly since > 0.6 not met)
    var summary = npc_rels.get_relationship_summary("alex")
    if summary == "Friendly":
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Summary should be 'Friendly', got '", summary, "'")
        failed += 1

    # Test 6b: High suspicion summary
    npc_rels.modify_suspicion("alex", 0.25)  # 0.6 + 0.25 = 0.85 > 0.8
    summary = npc_rels.get_relationship_summary("alex")
    if summary == "Hostile":
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Summary should be 'Hostile', got '", summary, "'")
        failed += 1

    # Test 7: Willing to talk at low suspicion
    npc_rels.reset()
    if npc_rels.is_willing_to_talk("alex"):
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Should be willing to talk at base suspicion")
        failed += 1

    # Test 8: Willing to talk at high suspicion
    npc_rels.modify_suspicion("alex", 0.6)  # 0.3 + 0.6 = 0.9 > 0.8
    if not npc_rels.is_willing_to_talk("alex"):
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Should not be willing to talk at high suspicion")
        failed += 1

    # Test 9: Resistance modifier
    npc_rels.reset()
    npc_rels.modify_trust("alex", 0.3)  # trust = 0.8
    var modifier = npc_rels.get_resistance_modifier("alex")
    if modifier > 0.0:
        passed += 1
        print("PASS: test_npc_relationships")
    else:
        print("FAIL: Resistance modifier should be positive with high trust")
        failed += 1

    print("=== ", passed, " passed, ", failed, " failed ===")
    quit()
