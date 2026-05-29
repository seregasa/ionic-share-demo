import { Component } from '@angular/core';
import { SharePreview } from '../../plugin/share-preview.plugin';

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
  standalone: false,
})
export class HomePage {

  async shareUrl() {
    await SharePreview.share({
      title: 'Custom title',
      url: 'https://example.com',
    });
  }

  async shareText() {
    await SharePreview.share({
      title: 'Custom title',
      text: 'Custom message text goes here',
    });
  }
}
