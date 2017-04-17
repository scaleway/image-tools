package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"
	"strings"

	"github.com/Sirupsen/logrus"
)

const ManifestURL = "https://raw.githubusercontent.com/scaleway/image-tools/master/public-images.manifest"

type Image struct {
	Name   string
	Tags   []string
	Repo   string
	Path   string
	Branch string
}

func (i *Image) RepoHost() string {
	return strings.Split(i.Repo, "/")[0]
}

func (i *Image) RepoPath() string {
	return strings.Join(strings.Split(i.Repo, "/")[1:], "/")
}

func (i *Image) RawContentUrl(path string) (string, error) {
	switch i.RepoHost() {
	case "github.com":
		prefix := i.Path
		if prefix == "." {
			prefix = ""
		}
		return fmt.Sprintf("https://raw.githubusercontent.com/%s/%s/%s/%s", i.RepoPath(), i.Branch, prefix, path), nil
	}
	return "", fmt.Errorf("Unhandled repository service: %q", i.RepoHost())
}

func (i *Image) FullName() string {
	return fmt.Sprintf("%s:%s", i.Name, i.Tags[0])
}

func (i *Image) GetDockerfile() (string, error) {
	url, err := i.RawContentUrl("Dockerfile")
	if err != nil {
		return "", err
	}
	logrus.Infof("Fetching Dockerfile for %s (%s)", i.FullName(), url)

	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", nil
	}

	return string(body), nil
}

type Manifest struct {
	Images []Image
}

func GetManifest(manifestURL string) (*Manifest, error) {
	resp, err := http.Get(manifestURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	scanner := bufio.NewScanner(resp.Body)

	re := regexp.MustCompile(`\ +`)

	manifest := Manifest{
		Images: make([]Image, 0),
	}

	for scanner.Scan() {
		line := scanner.Text()
		line = strings.TrimSpace(line)
		if len(line) < 1 || line[0] == '#' {
			continue
		}
		cols := re.Split(line, -1)
		if len(cols) < 4 {
			logrus.Warnf("Cannot parse manifest line %q: invalid amount of columns", line)
		}
		newEntry := Image{
			Name:   cols[0],
			Tags:   strings.Split(cols[1], ","),
			Repo:   cols[2],
			Path:   cols[3],
			Branch: "master",
		}
		manifest.Images = append(manifest.Images, newEntry)
	}

	return &manifest, nil
}

func main() {
	logrus.Infof("Fetching manifest...")
	manifest, err := GetManifest(ManifestURL)
	if err != nil {
		logrus.Fatalf("Cannot get manifest: %v", err)
	}
	logrus.Infof("Manifest fetched: %d images", len(manifest.Images))

	/*
		logrus.Infof("Initializing Docker client...")
		token := &oauth2.Token{AccessToken: os.Getenv("GITHUB_TOKEN")}
		ts := oauth2.StaticTokenSource(token)
		tc := oauth2.NewClient(oauth2.NoContext, ts)
		client := github.NewClient(tc)
		logrus.Infof("Docker client initialized")
	*/

	for _, image := range manifest.Images {
		dockerfile, err := image.GetDockerfile()
		if err != nil {
			logrus.Errorf("Cannot get Dockerfile for %s:%s", image.Name, image.Tags)
		}

		fmt.Println(dockerfile)

		// break -> only 1 image for now
		break
	}
}
