# MELD_INTEGRATION_PLAN03.md

## 범위
P5: 3-way Diff Core + 3-pane Compare UI
P6: 3-way Merge + Conflict Resolver + Merge Result

## P5 핵심 모델
- LOCAL / BASE / REMOTE
- equal / localOnly / remoteOnly / sameChange / conflict
- BASE 기준으로 BASE↔LOCAL, BASE↔REMOTE를 계산 후 base-range 기준으로 병합

## P5 파일 구조
Sources/Core/Diff3/
- ThreeWayDiffChunk.swift
- ThreeWayDiffResult.swift
- ThreeWayDiffOptions.swift
- ThreeWayDiffEngine.swift

Sources/State/Compare/
- ThreeWayDiffState.swift

Sources/Views/Compare/
- ThreeWayDiffView.swift
- ThreeWayTextPane.swift
- ThreeWayOverviewMap.swift
- ThreeWayDiffWindowPresenter.swift

## P5 Definition of Done
- LOCAL/BASE/REMOTE 3-way 비교
- localOnly / remoteOnly / sameChange / conflict 판정
- 3-pane read-only UI
- previous/next change
- conflict navigation
- overview map
- Core UI 비의존
- 테스트 통과

## P6 핵심 모델
MergeDecision:
- useLocal
- useRemote
- useBase
- useBothLocalThenRemote
- useBothRemoteThenLocal

자동 병합:
- equal → 자동
- localOnly → local
- remoteOnly → remote
- sameChange → local 또는 remote
- conflict → unresolved

## P6 파일 구조
Sources/Core/Merge/
- MergeDecision.swift
- MergeResult.swift
- ThreeWayMergeEngine.swift

Sources/State/Compare/
- ThreeWayMergeState.swift

Sources/Views/Compare/
- ThreeWayMergeView.swift
- MergeDecisionGutter.swift
- MergeResultPane.swift
- ConflictNavigator.swift

## P6 Definition of Done
- auto merge
- unresolved conflict tracking
- local/remote/base 선택
- both-order 선택
- merged result view
- save result
- unresolved count 표시
- 테스트 통과
- P0~P5 회귀 없음

## 구현 순서
P5:
1. ThreeWayDiffChunk.swift
2. ThreeWayDiffResult.swift
3. ThreeWayDiffEngine.swift
4. ThreeWayDiffState.swift
5. ThreeWayTextPane.swift
6. ThreeWayDiffView.swift
7. ThreeWayOverviewMap.swift
8. presenter
9. tests

P6:
1. MergeDecision.swift
2. MergeResult.swift
3. ThreeWayMergeEngine.swift
4. ThreeWayMergeState.swift
5. MergeDecisionGutter.swift
6. ThreeWayMergeView.swift
7. MergeResultPane.swift
8. tests

## 브랜치
feature/meld-p5-p6
