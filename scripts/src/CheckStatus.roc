CheckStatus := [].{
	succeeded = |code| code == 0 or code == 2
}

expect CheckStatus.succeeded(0)
expect CheckStatus.succeeded(2)
expect !CheckStatus.succeeded(1)
