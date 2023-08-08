package github

type ReviewTimeRoot struct {
	Data struct {
		Repository struct {
			PullRequest struct {
				Additions int    `json:"additions"`
				Deletions int    `json:"deletions"`
				Title     string `json:"title"`
				Body      string `json:"body"`
				Author    Author `json:"author"`
				// レビュー時間の取得元候補
				Comments Comments `json:"comments"`
				// レビュー時間の取得元候補
				Reviews Comments `json:"reviews"`
			} `json:"pullRequest"`
		} `json:"repository"`
	} `json:"data"`
	Errors Errors `json:"errors"`
}

type ReviewCommentsRoot struct {
	Data struct {
		Repository struct {
			PullRequest struct {
				Author        Author `json:"author"`
				ReviewThreads struct {
					Edges []struct {
						Node struct {
							Id         string   `json:"id"`
							IsResolved bool     `json:"isResolved"`
							Comments   Comments `json:"comments"`
						} `json:"node"`
						Cursor string `json:"cursor"`
					} `json:"edges"`
					PageInfo PageInfo
				} `json:"reviewThreads"`
			} `json:"pullRequest"`
		} `json:"repository"`
	} `json:"data"`
	Errors Errors `json:"errors"`
}

type Comments struct {
	Edges []struct {
		Node   Comment `json:"node"`
		Cursor string  `json:"cursor"`
	} `json:"edges"`
	PageInfo PageInfo `json:"pageInfo"`
}

type Comment struct {
	Url string `json:"url"`
	// Bodyが空文字列のものは無視する
	Body      string `json:"body"`
	Author    Author `json:"author"`
	CreatedAt string `json:"createdAt"`
}

type Author struct {
	Login string `json:"login"`
}

type PageInfo struct {
	HasNextPage bool   `json:"hasNextPage"`
	EndCursor   string `json:"endCursor"`
}

type Errors []struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}
