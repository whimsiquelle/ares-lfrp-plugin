import Component from '@ember/component';
import { inject as service } from '@ember/service';
import { action } from '@ember/object';
import { later, cancel } from '@ember/runloop';

const LFRP_REFRESH_INTERVAL = 20000;

export default Component.extend({
  tagName: '',

  gameApi: service(),
  flashMessages: service(),

  lfrpRefreshTimer: null,

  didInsertElement() {
    this._super(...arguments);

    this.refreshLfrp();
    this.scheduleLfrpRefresh();
  },

  willDestroyElement() {
    this._super(...arguments);

    this.cancelLfrpRefresh();
  },

  scheduleLfrpRefresh() {
    this.cancelLfrpRefresh();

    let timer = later(this, function() {
      this.refreshLfrp()
        .finally(() => {
          if (!this.isDestroying && !this.isDestroyed) {
            this.scheduleLfrpRefresh();
          }
        });
    }, LFRP_REFRESH_INTERVAL);

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
