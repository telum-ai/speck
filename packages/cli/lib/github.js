/**
 * GitHub API utilities for fetching Speck releases
 */

const REPO_OWNER = 'telum-ai';
const REPO_NAME = 'speck';
const API_BASE = 'https://api.github.com';

/**
 * Fetch all releases from GitHub
 */
export async function fetchReleases() {
  const response = await fetch(
    `${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/releases`,
    {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'speck-cli',
      },
    }
  );
  
  if (!response.ok) {
    throw new Error(`Failed to fetch releases: ${response.statusText}`);
  }
  
  return response.json();
}

/**
 * Get the latest release
 */
export async function getLatestRelease() {
  const response = await fetch(
    `${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest`,
    {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'speck-cli',
      },
    }
  );
  
  if (!response.ok) {
    throw new Error(`Failed to fetch latest release: ${response.statusText}`);
  }
  
  return response.json();
}

/**
 * Get a specific release by tag
 */
export async function getReleaseByTag(tag) {
  const response = await fetch(
    `${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${tag}`,
    {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'speck-cli',
      },
    }
  );
  
  if (!response.ok) {
    if (response.status === 404) {
      throw new Error(`Release ${tag} not found`);
    }
    throw new Error(`Failed to fetch release ${tag}: ${response.statusText}`);
  }
  
  return response.json();
}

/**
 * Download and extract a release tarball
 * Returns a map of file paths to contents
 */
export async function downloadRelease(tag) {
  const tarballUrl = `https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/tags/${tag}.tar.gz`;
  
  const response = await fetch(tarballUrl, {
    headers: {
      'User-Agent': 'speck-cli',
    },
  });
  
  if (!response.ok) {
    throw new Error(`Failed to download release: ${response.statusText}`);
  }
  
  // Return the tarball URL for extraction
  return {
    url: tarballUrl,
    tag,
  };
}

/**
 * Get the changelog between two versions
 */
export async function getChangelog(fromVersion, toVersion) {
  const releases = await fetchReleases();
  
  // Find releases between fromVersion and toVersion
  const fromIndex = releases.findIndex(r => r.tag_name === fromVersion);
  const toIndex = releases.findIndex(r => r.tag_name === toVersion);
  
  if (fromIndex === -1 || toIndex === -1) {
    return null;
  }
  
  // Get releases in between (releases are sorted newest first)
  const relevantReleases = releases.slice(toIndex, fromIndex);
  
  return relevantReleases.map(r => ({
    version: r.tag_name,
    name: r.name,
    body: r.body,
    publishedAt: r.published_at,
    url: r.html_url,
  }));
}
