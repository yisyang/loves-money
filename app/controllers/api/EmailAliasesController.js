// Generated by CoffeeScript 1.8.0
(function() {
  var EmailAliasesController, Promise, hmacSha1,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  hmacSha1 = require('crypto-js/hmac-sha1');

  Promise = require('bluebird');

  EmailAliasesController = (function() {
    function EmailAliasesController() {}

    EmailAliasesController.reservedAliases = ['', 'abuse', 'admin', 'administrator', 'billing', 'demo', 'dev', 'help', 'hostmaster', 'info', 'postmaster', 'qa', 'ssl-admin', 'support', 'test', 'testing', 'webmaster'];

    EmailAliasesController.getIndex = function(req, res) {
      res.fail('Invalid route, please use the UI at loves.money or view github source for valid requests.');
    };

    EmailAliasesController.formatAlias = function(alias) {
      return {
        customerId: alias.customerId,
        alias: alias.srcName,
        email: alias.destEmail
      };
    };

    EmailAliasesController.getAlias = function(req, res) {
      req.app.getModel('EmailAlias').findOne({
        srcName: req.params.alias
      }).then(function(emailAlias) {
        var destEmailDomain, destEmailName;
        if (emailAlias) {
          destEmailName = emailAlias.destEmail.substring(0, 1) + '*******';
          destEmailDomain = emailAlias.destEmail.substring(emailAlias.destEmail.indexOf('@'));
          emailAlias.destEmail = destEmailName + destEmailDomain;
          res.success(EmailAliasesController.formatAlias(emailAlias));
        } else {
          res.fail('Alias not found');
        }
      })["catch"](function(err) {
        res.fail('Unable to get alias', 500, null, err);
      });
    };

    EmailAliasesController.postAlias = function(req, res) {
      var EmailAlias, currentUser, newAlias, _ref;
      currentUser = req.app.get('user');
      newAlias = {
        customerId: currentUser.id,
        srcName: req.body.alias,
        destEmail: req.body.email
      };
      if (!newAlias.srcName || (_ref = newAlias.srcName, __indexOf.call(EmailAliasesController.reservedAliases, _ref) >= 0)) {
        res.fail('Requested alias is reserved');
        return;
      }
      EmailAlias = req.app.getModel('EmailAlias');
      EmailAlias.create(newAlias).then(function(alias) {
        req.app.getModel('VirtualAlias').create({
          domainId: req.app.get('config').mailserver_domain_id,
          source: newAlias.srcName + '@loves.money',
          destination: newAlias.destEmail
        }).then(function() {
          return res.success(EmailAliasesController.formatAlias(alias));
        })["catch"](function(err) {
          EmailAlias.destroy({
            id: alias.id
          }, function() {});
          res.fail('Error creating mail alias', 500, null, err);
        });
      })["catch"](function(err) {
        EmailAlias.findOne().where({
          srcName: newAlias.srcName
        }).then(function(alias) {
          if (alias) {
            res.fail('The alias is already registered');
            throw false;
          }
          return EmailAlias.findOne().where({
            destEmail: newAlias.destEmail
          }).then(function(alias) {
            return alias;
          });
        }).then(function(alias) {
          if (alias) {
            res.fail('The email is already registered');
            throw false;
          } else {
            throw err;
          }
        })["catch"](function(err) {
          if (err) {
            res.fail('Error creating alias', 500, null, err);
          }
        });
      });
    };

    EmailAliasesController.deleteAlias = function(req, res) {
      var EmailAlias, _ref;
      if (!req.params.alias || (_ref = req.params.alias, __indexOf.call(EmailAliasesController.reservedAliases, _ref) >= 0)) {
        res.fail('Requested alias is reserved');
        return;
      }
      EmailAlias = req.app.getModel('EmailAlias');
      EmailAlias.findOne().where({
        srcName: req.params.alias
      }).then(function(alias) {
        var currentUser;
        if (!alias) {
          res.fail('Alias not found');
          throw false;
        }
        currentUser = req.app.get('user');
        if (currentUser.id !== alias.customerId && !currentUser.isAdmin) {
          res.fail('You are not the owner of this alias!', 401);
          return;
        }
        req.app.getModel('VirtualAlias').destroy({
          domainId: req.app.get('config').mailserver_domain_id,
          destination: alias.destEmail,
          custom: true
        }).then(function() {
          return EmailAlias.destroy({
            id: alias.id
          });
        }).then(function() {
          res.success();
        })["catch"](function(err) {
          res.fail('Unable to delete alias', 500, null, err);
        });
      })["catch"](function(err) {
        if (err) {
          res.fail('Unable to get alias', 500, null, err);
        }
      });
    };

    EmailAliasesController.deleteAll = function(req, res) {
      var currentUser;
      if (req.app.get('config').env === !'development') {
        res.fail('Forbidden', 403);
        return;
      }
      currentUser = req.app.get('user');
      if (!currentUser.isAdmin) {
        res.fail('Not authorized', 401);
        return;
      }
      req.app.getModel('EmailAlias').query('TRUNCATE TABLE email_aliases').then(function() {
        return req.app.getModel('VirtualAlias').destroy({
          custom: true
        });
      }).then(function() {
        res.success();
      })["catch"](function(err) {
        if (err) {
          res.fail('Unable to truncate aliases', 500, null, err);
        }
      });
    };

    return EmailAliasesController;

  })();

  module.exports = EmailAliasesController;

}).call(this);

//# sourceMappingURL=EmailAliasesController.js.map
