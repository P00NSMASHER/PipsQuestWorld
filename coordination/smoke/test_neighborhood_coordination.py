"""Coordination invariants only; passing these tests is not game acceptance."""
import copy
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATE_PATH = "coordination/state/NEIGHBORHOOD_WORKERS.json"
INDEX_PATH = "coordination/HIGH_SCHOOL_SWARM_STATE.json"


def overlaps(a, b):
    a_prefix = a[:-3] if a.endswith('/**') else None
    b_prefix = b[:-3] if b.endswith('/**') else None
    return (a == b or (a_prefix is not None and b.startswith(a_prefix + '/'))
            or (b_prefix is not None and a.startswith(b_prefix + '/')))


def validate(state, index):
    def require(ok, message):
        if not ok:
            raise ValueError(message)
    require(state['direction'] == index['activeDirection'], 'direction mismatch')
    require(state['queueIssue'] == index['activeQueueIssue'], 'queue mismatch')
    require(index['authoritativeShards']['neighborhoodWorkers'] == STATE_PATH, 'wrong state shard')
    require('coordination/state/WIP.json' not in index['authoritativeShards'].values(), 'legacy WIP still authoritative')
    require(index['readOrder'][0] == 'coordination/HIGH_SCHOOL_CANONICAL_SCOPE_OVERRIDE.md', 'scope must be read first')
    require(state['candidate']['buildProject'] == index['activeBuildProject'] == 'school/neighborhood.project.json', 'wrong build target')
    require(state['wip']['currentProducerPr'] == state['candidate']['pr'], 'competing product candidate')
    require(state['wip']['capIncludingBase'] == 3, 'WIP cap changed')
    for record in (state['canonical'], state['candidate']):
        require(re.fullmatch(r'[0-9a-f]{40}', record['observedSha']) is not None, 'invalid observed SHA')
    execution = state['execution']
    require(execution['verifiedScheduledRobloxWorkers'] == 15, 'scheduled worker allocation drift')
    require(execution['scheduledTasksChanged'] is True, 'explicit worker reallocation missing')
    require(execution['agentLaunchClaimed'] is False, 'agent launch was not performed')
    priority = state.get('topPriority', {})
    require(priority.get('issue') == 304, 'top priority issue drift')
    require(priority.get('referenceFolder') == '/Roblox/ABVM References', 'reference folder drift')
    require(len(priority.get('libraryRefs', [])) == 10, 'ABVM reference inventory drift')
    lanes = {lane['id']: lane for lane in state['lanes']}
    require(len(lanes) == len(state['lanes']), 'duplicate lane')
    paths = []
    for lane in state['lanes']:
        require(lane['handoffTo'] in lanes, 'unknown handoff receiver')
        for path in lane['paths']:
            require(not any(overlaps(path, old) for _, old in paths), 'overlapping lane paths')
            paths.append((lane['id'], path))
    jobs = {job['id']: job for job in state['priorityQueue']}
    require(len(jobs) == len(state['priorityQueue']), 'duplicate job')
    complete, visiting = set(), set()
    def visit(job_id):
        require(job_id in jobs, 'unknown dependency')
        require(job_id not in visiting, 'dependency cycle')
        if job_id in complete:
            return
        visiting.add(job_id)
        require(jobs[job_id]['owner'] in lanes, 'unknown owner')
        for dependency in jobs[job_id]['dependsOn']:
            visit(dependency)
        visiting.remove(job_id)
        complete.add(job_id)
    for job_id in jobs:
        visit(job_id)
    contract = state['contract']
    require(contract['walletFloor'] == 0, 'debt is forbidden')
    require(contract['positiveStreakBonus'] == [0, 2, 4, 6, 8, 10], 'positive ladder drift')
    require(contract['negativeStreakDeduction'] == [2, 4, 6, 8, 10], 'negative ladder drift')
    require(contract['baseIndependent'] == 10 and contract['baseSupported'] == 6, 'base tuning drift')
    require(contract['lessonEvery'] == 5 and contract['lessonBonus'] == 15, 'lesson tuning drift')
    require(5 * contract['baseIndependent'] + sum(contract['positiveStreakBonus'][:5]) + contract['lessonBonus'] == 85, 'five-answer payout drift')
    require(len(set(contract['subjects'])) == 6, 'six subjects required')
    require(contract['boards'] == ['Highest Accuracy', 'Most Questions', 'Most Credits'], 'board mismatch')
    require(contract['accuracyMinimumAttempts'] == 20, 'accuracy qualification drift')
    require(contract['creditsBasis'] == 'CURRENT_SPENDABLE_BALANCE', 'cash board must not mean lifetime earnings')


class NeighborhoodCoordinationTests(unittest.TestCase):
    def setUp(self):
        self.state = json.loads((ROOT / STATE_PATH).read_text())
        self.index = json.loads((ROOT / INDEX_PATH).read_text())

    def test_current_assignment_graph(self):
        validate(self.state, self.index)

    def test_reject_legacy_project_and_old_authority(self):
        state = copy.deepcopy(self.state)
        state['candidate']['buildProject'] = 'school/default.project.json'
        with self.assertRaisesRegex(ValueError, 'build target'):
            validate(state, self.index)
        index = copy.deepcopy(self.index)
        index['authoritativeShards']['wip'] = 'coordination/state/WIP.json'
        with self.assertRaisesRegex(ValueError, 'legacy WIP'):
            validate(self.state, index)

    def test_reject_duplicate_owner_paths(self):
        self.state['lanes'][1]['paths'].append(self.state['lanes'][2]['paths'][0])
        with self.assertRaisesRegex(ValueError, 'overlapping'):
            validate(self.state, self.index)

    def test_reject_wildcard_owner_collision(self):
        self.state['lanes'][1]['paths'] = ['school/neighborhood/server/**']
        with self.assertRaisesRegex(ValueError, 'overlapping'):
            validate(self.state, self.index)

    def test_reject_dependency_cycle(self):
        self.state['priorityQueue'][0]['dependsOn'] = ['A08']
        with self.assertRaisesRegex(ValueError, 'cycle'):
            validate(self.state, self.index)

    def test_reject_competing_producer(self):
        self.state['wip']['currentProducerPr'] = 300
        with self.assertRaisesRegex(ValueError, 'competing'):
            validate(self.state, self.index)

    def test_reject_other_economy_tuning_and_debt(self):
        for field, value in [('baseIndependent', 25), ('walletFloor', -100), ('lessonBonus', 50)]:
            state = copy.deepcopy(self.state)
            state['contract'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                validate(state, self.index)

    def test_reject_unperformed_launch_claim(self):
        self.state['execution']['agentLaunchClaimed'] = True
        with self.assertRaisesRegex(ValueError, 'agent launch'):
            validate(self.state, self.index)


if __name__ == '__main__':
    unittest.main()
