import Component from '@ember/component';
import { inject as service } from '@ember/service';
import { action } from '@ember/object';
import { later, cancel } from '@ember/runloop';

const DEFAULT_LFRP_REFRESH_SECONDS = 20;

export default Component.extend({
  tagName: '',

  gameApi: service(),
  flashMessages: service(),

  lfrpRefreshTimer: null,

  didInsertElement() {
    this._super(...arguments);

    this.refreshLfrp()
      .finally(() => {
        if (!this.isDestroying && !this.isDestroyed) {
          this.scheduleLfrpRefresh();
        }
      });
  },

  willDestroyElement() {
    this._super(...arguments);

    this.cancelLfrpRefresh();
  },

  lfrpRefreshSeconds() {
    let seconds = parseInt(this.get('custom.lfrp_refresh_seconds'), 10);

    if (isNaN(seconds)) {
      return DEFAULT_LFRP_REFRESH_SECONDS;
    }

    if (seconds === 0) {
      return 0;
    }

    if (seconds < 5) {
      return 5;
    }

    if (seconds > 60) {
      return 60;
    }

    return seconds;
  },

  scheduleLfrpRefresh() {
    this.cancelLfrpRefresh();

    let seconds = this.lfrpRefreshSeconds();

    if (seconds === 0) {
      return;
    }

    let timer = later(this, function() {
      this.refreshLfrp()
        .finally(() => {
          if (!this.isDestroying && !this.isDestroyed) {
            this.scheduleLfrpRefresh();
          }
        });
    }, seconds * 1000);

    this.set('lfrpRefreshTimer', timer);
  },

  cancelLfrpRefresh() {
    let timer = this.get('lfrpRefreshTimer');

    if (timer) {
      cancel(timer);
      this.set('lfrpRefreshTimer', null);
    }
  },

  refreshLfrp() {
    return this.gameApi.requestOne('lfrpList', {}, null)
      .then((response) => {
        if (this.isDestroying || this.isDestroyed) {
          return;
        }

        this.set('custom.lfrp', response.lfrp || []);

        if (response.hasOwnProperty('lfrp_can_use')) {
          this.set('custom.lfrp_can_use', response.lfrp_can_use);
        }

        if (response.hasOwnProperty('lfrp_active')) {
          this.set('custom.lfrp_active', response.lfrp_active);
        }

        if (response.hasOwnProperty('lfrp_refresh_seconds')) {
          this.set('custom.lfrp_refresh_seconds', response.lfrp_refresh_seconds);
        }
      })
      .catch(() => {
        // Background refresh failures remain silent.
      });
  },

  lookForAnyRp: action(function() {
    this.startLookingForRp('any');
  }),

  lookForTxtRp: action(function() {
    this.startLookingForRp('txt');
  }),

  lookForLiveRp: action(function() {
    this.startLookingForRp('live');
  }),

  lookForAsyncRp: action(function() {
    this.startLookingForRp('async');
  }),

  startLookingForRp(sceneType) {
    this.gameApi.requestOne('lfrpStart', {
      scene_type: sceneType
    }, null)
      .then(() => {
        switch (sceneType) {
          case 'txt':
            this.flashMessages.success('You are now looking for TXT-only RP.');
            break;
          case 'live':
            this.flashMessages.success('You are now looking for live RP.');
            break;
          case 'async':
            this.flashMessages.success('You are now looking for async RP.');
            break;
          default:
            this.flashMessages.success('You are now looking for any scene.');
            break;
        }

        this.refreshLfrp();
      })
      .catch((err) => {
        this.flashMessages.danger(err);
      });
  },

  stopLookingForRp: action(function() {
    this.gameApi.requestOne('lfrpStop', {}, null)
      .then(() => {
        this.flashMessages.success('You are no longer looking for RP.');
        this.refreshLfrp();
      })
      .catch((err) => {
        this.flashMessages.danger(err);
      });
  })
});
