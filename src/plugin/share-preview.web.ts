import { WebPlugin } from '@capacitor/core';
import { SharePreviewPlugin } from './share-preview.plugin';

export class SharePreviewWeb extends WebPlugin implements SharePreviewPlugin {
  async share(options: { title: string; text?: string; url?: string }): Promise<void> {
    if (navigator.share) {
      await navigator.share({ title: options.title, text: options.text, url: options.url });
    } else {
      alert(`[Web fallback]\nTitle: ${options.title}\n${options.url || options.text}`);
    }
  }
}
