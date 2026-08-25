import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'OpenIM React Native SDK',
  tagline: 'React Native bridge for the OpenIM chat SDK',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://droppii.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/open-im-sdk-reactnative/',
  // NOTE: trailingSlash intentionally left unset (defaults to false-ish/undefined).
  // @easyops-cn/docusaurus-search-local fetches a static file (search-index.json) and
  // does not account for trailingSlash, so enabling it 404s that request and the search
  // box spins forever. GitHub Pages works fine without trailingSlash for this site.

  // GitHub pages deployment config.
  organizationName: 'droppii',
  projectName: 'open-im-sdk-reactnative',
  deploymentBranch: 'gh-pages',

  onBrokenLinks: 'warn',

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/', // serve docs at the site root, no /docs/ prefix
          editUrl:
            'https://github.com/droppii/open-im-sdk-reactnative/tree/main/website/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themes: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        indexDocs: true,
        indexBlog: false,
        indexPages: false,
        docsRouteBasePath: '/',
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
      },
    ],
  ],

  themeConfig: {
    image: 'img/docusaurus-social-card.jpg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'OpenIM RN SDK',
      logo: {
        alt: 'OpenIM logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: 'https://www.npmjs.com/package/@droppii/openim-rn-client-sdk',
          label: 'npm',
          position: 'right',
        },
        {
          href: 'https://github.com/droppii/open-im-sdk-reactnative',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {label: 'Introduction', to: '/'},
            {label: 'Quick Start', to: '/quick-start'},
            {label: 'API Reference', to: '/api-reference'},
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'npm package',
              href: 'https://www.npmjs.com/package/@droppii/openim-rn-client-sdk',
            },
            {
              label: 'GitHub',
              href: 'https://github.com/droppii/open-im-sdk-reactnative',
            },
            {
              label: 'OpenIM',
              href: 'https://www.openim.io',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Droppii. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
