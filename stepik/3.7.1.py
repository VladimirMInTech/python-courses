def main():
    count_games = int(input())
    results: dict = {}
    for i in range(count_games):
        match_result = input()
        team1, score1, team2, score2 = match_result.split(';')
        score1, score2 = int(score1), int(score2)

        if team1 not in results:
            results[team1] = {'games': 0, 'wins': 0, 'draws': 0, 'losses': 0, 'points': 0}
        if team2 not in results:
            results[team2] = {'games': 0, 'wins': 0, 'draws': 0, 'losses': 0, 'points': 0}

        results[team1]['games'] += 1
        results[team2]['games'] += 1

        if score1 > score2:
            results[team1]['wins'] += 1
            results[team1]['points'] += 3
            results[team2]['losses'] += 1
        elif score1 < score2:
            results[team1]['losses'] += 1
            results[team2]['wins'] += 1
            results[team2]['points'] += 3
        else:
            results[team1]['draws'] += 1
            results[team1]['points'] += 1
            results[team2]['draws'] += 1
            results[team2]['points'] += 1

    for team, stats in results.items():
        print(f"{team}: {stats['games']} {stats['wins']} {stats['draws']} {stats['losses']} {stats['points']}")


if __name__ == "__main__":
    main()
